import {readFile} from 'node:fs/promises';
import {parse} from 'dotenv';
import {Client} from 'pg';
const tag=process.argv[2];
if(!/^\d{10,18}$/.test(tag??''))throw new Error('Informe somente o identificador numérico do ensaio.');
const env=parse(await readFile('.env'));const url=new URL(env.DATABASE_URL);
if(!['localhost','127.0.0.1'].includes(url.hostname))throw new Error('Somente banco local.');
url.pathname='/miar_test';const db=new Client({connectionString:url.toString()});await db.connect();
let deleted=0;
try{
 for(let i=0;i<3;i++){
  const email=`apresentacao-${tag}-${i}@example.test`;
  const user=(await db.query('SELECT id_usuario FROM "USUARIO" WHERE email=$1',[email])).rows[0];
  if(!user)continue;
  const login=await fetch('http://127.0.0.1:3301/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email,senha:'Apresentacao!42'})});
  if(login.status!==200)throw new Error('Não foi possível autenticar a conta de teste para limpeza.');
  const auth=await login.json();if(auth.usuario.id_usuario!==user.id_usuario)throw new Error('API e banco de teste divergentes.');
  const headers={Authorization:'Bearer '+auth.token};
  const records=await (await fetch('http://127.0.0.1:3301/ocorrencias/minhas',{headers})).json();
  for(const o of records.items){const r=await fetch('http://127.0.0.1:3301/ocorrencias/'+o.id_ocorrencia,{method:'DELETE',headers});if(r.status!==200)throw new Error('Falha ao excluir ocorrência de teste.');deleted++;}
  await fetch('http://127.0.0.1:3301/auth/logout',{method:'POST',headers});
  await db.query('DELETE FROM "USUARIO" WHERE id_usuario=$1 AND email=$2',[user.id_usuario,email]);
 }
 console.log('Ensaio '+tag+': '+deleted+' ocorrências de teste removidas; contas desta execução removidas.');
}finally{await db.end();}
