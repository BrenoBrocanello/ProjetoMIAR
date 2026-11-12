import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile,writeFile,mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { Client } from 'pg';
import { S3Client,ListObjectsV2Command } from '@aws-sdk/client-s3';
import { ResultadosIA } from '../dist/infra/resultados-ia.js';

const base=process.env.API_TEST_URL;
const url=new URL(process.env.DATABASE_URL);
if(!base || !['localhost','127.0.0.1'].includes(url.hostname) || !url.pathname.endsWith('_test')) throw new Error('Auditoria exige banco local isolado.');
const db=new Client({connectionString:url.toString()});
const monitor=new Client({connectionString:url.toString()});
const store=new ResultadosIA();
const photo=await readFile('../prototipos/assets/img/ocorrencia-cao-grande.jpg');
const other=await readFile('../prototipos/assets/img/ocorrencia-gato-filhote.jpg');
const tag=Date.now().toString(),users=[],occs=[],bulk=[];
const city='Auditoria '+tag;
const s3=new S3Client({endpoint:process.env.S3_ENDPOINT,region:'us-east-1',forcePathStyle:true,
 credentials:{accessKeyId:process.env.S3_ACCESS_KEY,secretAccessKey:process.env.S3_SECRET_KEY}});
const reportDir=resolve(process.env.TEST_REPORT_DIR ?? '../evidencias');
async function request(path,{method='GET',token,data,raw}={}) {
 const r=await fetch(base+path,{method,headers:{...(token?{Authorization:'Bearer '+token}:{}),...(data?{'Content-Type':'application/json'}:{})},body:raw??(data?JSON.stringify(data):undefined)});
 return {status:r.status,body:r.status===204?null:await r.json()};
}
const occurrence=(extra={})=>({especie:'Cão',porte:'Grande',estado_saude:'Saudável',status_ocorrencia:'Perdido',descricao_fisica:'Auditoria '+tag,
 localizacao:{latitude:-23.1857,longitude:-46.8978,cidade:city,estado:'SP',endereco:'Endereço de teste'},numero_whatsapp:'11987654321',...extra});
async function save(token,data,files=[photo],id) {
 const form=new FormData();form.append('dados',typeof data==='string'?data:JSON.stringify(data));
 for(const file of files)form.append('fotos',new Blob([file],{type:'image/jpeg'}),'foto.jpg');
 return request('/ocorrencias'+(id?'/'+id:''),{method:id?'PUT':'POST',token,raw:form});
}
async function register(i,perfil='Cidadão') {
 const data={nome:'Auditoria '+i,email:`audit-${tag}-${i}@example.test`,senha:'Auditoria!42',telefone:'11987654321',tipo_usuario:perfil,documento:'Documento de teste'};
 const r=await request('/usuarios/cadastro',{method:'POST',data});assert.equal(r.status,201,JSON.stringify(r.body));users.push(r.body.id_usuario);
 const login=await request('/auth/login',{method:'POST',data:{email:data.email,senha:data.senha}});assert.equal(login.status,200);
 return {...login.body,credenciais:data};
}
async function created(user,data,files) {
 const r=await save(user.token,data,files);assert.equal(r.status,201,JSON.stringify(r.body));occs.push({id:r.body.id_ocorrencia,user});return r.body;
}
async function waitFor(fn) {for(let i=0;i<60;i++){if(await fn())return;await new Promise(r=>setTimeout(r,50));}throw new Error('Trava concorrente não observada.');}
async function objects(){return new Set((await s3.send(new ListObjectsV2Command({Bucket:process.env.S3_BUCKET}))).Contents?.map(x=>x.Key)??[]);}

await test('Auditoria MASTER: cenários alternativos, integridade, concorrência e desempenho',async t=>{
 await db.connect();await monitor.connect();let a,b,lost,found;
 try {
  a=await register(1);b=await register(2,'ONG');
  await t.test('RF01/RD01: perfis inválidos, sobreposição de campos e e-mail duplicado são recusados',async()=>{
   for(const extra of [{tipo_usuario:'Administrador'},{cpf:'123'},{nome_instituicao:'Extra'},{ativo:false},{id_usuario:1}]) {
    const r=await request('/usuarios/cadastro',{method:'POST',data:{...a.credenciais,email:'invalid-'+tag+'@example.test',...extra}});assert.equal(r.status,400);
   }
   const duplicate=await request('/usuarios/cadastro',{method:'POST',data:{...a.credenciais,email:a.credenciais.email.toUpperCase()}});assert.equal(duplicate.status,409);
  });
  await t.test('RF01: atualização inválida/duplicada é atômica; credenciais novas funcionam',async()=>{
   for(const data of [{nome:'Não gravar',telefone:'00123456789'},{nome:'Não gravar',email:b.credenciais.email},{tipo_usuario:'ONG'},{ativo:false}]) {
    const r=await request('/usuarios/me',{method:'PATCH',token:a.token,data});assert([400,409].includes(r.status));
    assert.equal((await request('/usuarios/me',{token:a.token})).body.nome,a.usuario.nome);
   }
   const email=`audit-${tag}-novo@example.test`,senha='Nova credencial!42';
   const r=await request('/usuarios/me',{method:'PATCH',token:a.token,data:{email,senha,documento:'Documento atualizado'}});assert.equal(r.status,200);assert.equal(r.body.documento,'Documento atualizado');assert(!('senha'in r.body));
   assert.equal((await request('/auth/login',{method:'POST',data:{email:a.credenciais.email,senha:a.credenciais.senha}})).status,401);
   const login=await request('/auth/login',{method:'POST',data:{email,senha}});assert.equal(login.status,200);a.token=login.body.token;
  });
  lost=await created(a,occurrence());found=await created(b,occurrence({status_ocorrencia:'Encontrado'}));
  await t.test('CU05/RD03: JSON, coordenadas, cidade, porte, status e fotos inválidos não persistem',async()=>{
   const before=Number((await db.query('SELECT count(*) FROM "OCORRENCIA_ANIMAL"')).rows[0].count);
   const invalid=[['{'],[occurrence({localizacao:null})],[occurrence({localizacao:{latitude:null,longitude:0,cidade:'X'}})],
    [occurrence({localizacao:{latitude:91,longitude:0,cidade:'X'}})],[occurrence({localizacao:{latitude:0,longitude:-181,cidade:'X'}})],
    [occurrence({localizacao:{latitude:0,longitude:0,cidade:' '}})],[occurrence({porte:'Gigante'})],[occurrence({status_ocorrencia:'Em avaliação'})],
    [occurrence({numero_whatsapp:'00123456789'})],[occurrence({administrador:true})],[occurrence(),[]],[occurrence(),[Buffer.from('imagem falsa')]],
    [occurrence(),Array(7).fill(photo)]];
   for(const [data,files]of invalid)assert.equal((await save(a.token,data,files)).status,400);
   assert.equal(Number((await db.query('SELECT count(*) FROM "OCORRENCIA_ANIMAL"')).rows[0].count),before);
  });
  await t.test('RF03: filtros individuais/combinados, paginação e tentativa SQL literal',async()=>{
   for(const query of ['status=Perdido','especie=C%C3%A3o','porte=Grande','cidade='+encodeURIComponent(city),'status=Perdido&especie=C%C3%A3o&porte=Grande&cidade='+encodeURIComponent(city)]) {
    const r=await request('/ocorrencias?'+query,{token:a.token});assert.equal(r.status,200);assert(r.body.items.some(x=>x.id_ocorrencia===lost.id_ocorrencia));
   }
   assert.equal((await request('/ocorrencias?cidade='+encodeURIComponent("' OR 1=1 --"),{token:a.token})).body.total,0);
   for(const query of ['pagina=-1','pagina=abc','status=Inexistente','usuario=1'])assert.equal((await request('/ocorrencias?'+query,{token:a.token})).status,400);
  });
  await t.test('CU06/CU07/RD02/RD06: seis status e supressão de contato em todos os retornos públicos',async()=>{
   for(const status of ['Perdido','Encontrado','Emergência','Aguardando Adoção','Adotado','Resgatado']) {
    const r=await request(`/ocorrencias/${found.id_ocorrencia}/status`,{token:b.token,method:'PATCH',data:{status_ocorrencia:status}});assert.equal(r.status,200);assert.equal(r.body.status_ocorrencia,status);
    const o=(await request('/ocorrencias/'+found.id_ocorrencia,{token:a.token})).body;
    const closed=['Adotado','Resgatado'].includes(status);assert.equal(o.contato===null,closed);
    const own=(await request(`/ocorrencias/${found.id_ocorrencia}/editar`,{token:b.token})).body;assert.equal(own.contato.numero_whatsapp,'11987654321');
    const link=await request('/contatos/'+found.id_ocorrencia,{token:a.token});assert.equal(link.status,closed?410:200);
    if(closed)for(const route of ['/ocorrencias','/localizacoes/radar']){
     const list=await request(route+'?cidade='+encodeURIComponent(city),{token:b.token});const row=list.body.items.find(x=>x.id_ocorrencia===found.id_ocorrencia);
     assert(row);assert.equal(row.contato,null);assert(!JSON.stringify(row).includes('11987654321'));
    }
   }
   await request(`/ocorrencias/${found.id_ocorrencia}/status`,{token:b.token,method:'PATCH',data:{status_ocorrencia:'Encontrado'}});
   assert.equal((await request(`/ocorrencias/${found.id_ocorrencia}/status`,{token:b.token,method:'PATCH',data:{status_ocorrencia:'Outro'}})).status,400);
  });
  await t.test('CU10: link usa o telefone persistido e não registra ou envia conversa',async()=>{
   const before=(await db.query('SELECT count(*) FROM "MENSAGEM_WHATSAPP"')).rows[0].count;
   const link=await request('/contatos/'+found.id_ocorrencia+'?numero_whatsapp=0000',{token:a.token});assert.equal(link.body.url,'https://wa.me/5511987654321');
   assert.equal((await db.query('SELECT count(*) FROM "MENSAGEM_WHATSAPP"')).rows[0].count,before);
  });
  await t.test('RD04/RNF05: IDs inválidos, token falso, exclusão/edição alheia e foto de terceiro',async()=>{
   assert.equal((await request('/usuarios/me',{token:'0'.repeat(64)})).status,401);
   assert.equal((await request('/ocorrencias/invalido',{token:a.token})).status,400);
   assert.equal((await request('/ocorrencias/2147483647',{token:a.token})).status,404);
   assert.equal((await request('/ocorrencias/'+lost.id_ocorrencia,{token:b.token,method:'DELETE'})).status,403);
   assert.equal((await save(b.token,occurrence(),[photo],lost.id_ocorrencia)).status,403);
   assert.equal((await save(a.token,occurrence({fotos_mantidas:found.fotos.map(x=>x.id_foto)}),[],lost.id_ocorrencia)).status,400);
  });
  await t.test('CU11/CU12: fotos alteradas invalidam resultado antigo; novo aviso continua consultável',async()=>{
   const matches=await request('/correspondencias',{token:a.token});const original=matches.body.find(x=>x.id_ocorrencia_origem===found.id_ocorrencia);assert(original);
   assert.equal((await request('/correspondencias/'+original.id_correspondencia,{token:b.token})).status,404);
   const altered=await save(b.token,occurrence({status_ocorrencia:'Encontrado',fotos_mantidas:[]}),[other],found.id_ocorrencia);assert.equal(altered.status,200);
   assert.equal((await request('/correspondencias/'+original.id_correspondencia,{token:a.token})).status,404);
   const restored=await save(b.token,occurrence({status_ocorrencia:'Encontrado',fotos_mantidas:[]}),[photo],found.id_ocorrencia);assert.equal(restored.status,200);found=restored.body;
   const next=(await request('/correspondencias',{token:a.token})).body.find(x=>x.id_ocorrencia_origem===found.id_ocorrencia);assert(next);assert.equal(next.status_notificacao,'Pendente');
  });
  await t.test('RNF03: falha no COMMIT reverte ocorrência, fotos, objetos e resultado de IA',async()=>{
   const marker='audit-reject-'+tag;
   await db.query(`CREATE FUNCTION miar_audit_reject() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN IF NEW.descricao LIKE '%${marker}%' THEN RAISE EXCEPTION 'falha de gravacao de teste'; END IF; RETURN NEW; END $$`);
   await db.query('CREATE CONSTRAINT TRIGGER miar_audit_reject AFTER INSERT ON "OCORRENCIA_ANIMAL" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION miar_audit_reject()');
   try {
    const before=(await db.query('SELECT count(*) FROM "OCORRENCIA_ANIMAL"')).rows[0].count;
    const results=JSON.stringify(await store.todos()),files=await objects();
    const r=await save(b.token,occurrence({descricao_fisica:marker,status_ocorrencia:'Encontrado'}));assert.equal(r.status,500);
    assert.equal((await db.query('SELECT count(*) FROM "OCORRENCIA_ANIMAL"')).rows[0].count,before);
    assert.equal(JSON.stringify(await store.todos()),results);assert.deepEqual(await objects(),files);
   } finally {await db.query('DROP TRIGGER miar_audit_reject ON "OCORRENCIA_ANIMAL"');await db.query('DROP FUNCTION miar_audit_reject()');}
  });
  await t.test('RF02: duas edições concorrentes não deixam ocorrência sem fotografia',async()=>{
   const current=(await request('/ocorrencias/'+found.id_ocorrencia,{token:b.token})).body;
   await db.query('BEGIN');await db.query('SELECT 1 FROM "OCORRENCIA_ANIMAL" WHERE id_ocorrencia=$1 FOR UPDATE',[found.id_ocorrencia]);
   let first,second;
   try {
    first=save(b.token,occurrence({status_ocorrencia:'Encontrado',fotos_mantidas:[]}),[photo],found.id_ocorrencia);
    await waitFor(async()=>Number((await monitor.query("SELECT count(*) FROM pg_stat_activity WHERE wait_event_type='Lock' AND query LIKE 'SELECT id_usuario_responsavel,id_animal%'")).rows[0].count)>=1);
    second=save(b.token,occurrence({status_ocorrencia:'Encontrado',fotos_mantidas:current.fotos.map(x=>x.id_foto)}),[],found.id_ocorrencia);
    await waitFor(async()=>Number((await monitor.query("SELECT count(*) FROM pg_stat_activity WHERE wait_event_type='Lock'")).rows[0].count)>=2);
   } finally {await db.query('COMMIT');}
   const [r1,r2]=await Promise.all([first,second]);assert.equal(r1.status,200);assert.equal(r2.status,409,JSON.stringify(r2.body));
   const after=(await request('/ocorrencias/'+found.id_ocorrencia,{token:b.token})).body;assert(after.fotos.length>0);assert.equal((await fetch(base+after.fotos[0].url_storage)).status,200);
  });
  await t.test('RNF02: galeria, filtros e paginação com 1.200 registros e cinco consultas simultâneas',async()=>{
   const ids=(await db.query(`INSERT INTO "OCORRENCIA_ANIMAL"(id_usuario_responsavel,id_animal,status_ocorrencia,descricao)
    SELECT $1,$2,CASE WHEN i%2=0 THEN 'Encontrado' ELSE 'Perdido' END,'Carga de auditoria' FROM generate_series(1,1200)i RETURNING id_ocorrencia`,[a.usuario.id_usuario,lost.animal.id_animal])).rows.map(x=>x.id_ocorrencia);bulk.push(...ids);
   await db.query('INSERT INTO "LOCALIZACAC"(id_ocorrencia,id_cidade,latitude,longitude) SELECT unnest($1::int[]),$2,-23.1857,-46.8978',[ids,lost.localizacao.id_cidade]);
   await db.query('INSERT INTO "FOTO"(id_ocorrencia,url_storage) SELECT unnest($1::int[]),$2',[ids,lost.fotos[0].url_storage]);
   const timings=[];
   for(let batch=0;batch<16;batch++)await Promise.all(Array.from({length:5},async(_,i)=>{
    const start=performance.now();const r=await request('/ocorrencias?cidade='+encodeURIComponent(city)+(i%2?'&status=Perdido&especie=C%C3%A3o&porte=Grande':''),{token:a.token});
    const ms=performance.now()-start;assert.equal(r.status,200);assert(r.body.total>=600);assert(r.body.items.length<=24);timings.push(ms);
   }));
   const first=await request('/localizacoes/radar?cidade='+encodeURIComponent(city),{token:b.token});assert.equal(first.body.items.length,1000);assert(first.body.total>=1200);
   const second=await request('/localizacoes/radar?cidade='+encodeURIComponent(city)+'&pagina=1',{token:b.token});assert(second.body.items.length>=200);
   const ordered=[...timings].sort((a,b)=>a-b),stats={registros:1200,simultaneidade:5,consultas:timings.length,max_ms:Math.max(...timings),p95_ms:ordered[Math.ceil(ordered.length*.95)-1],ambiente:'local; nao representa SLA ou carga de producao'};
   await mkdir(reportDir,{recursive:true});await writeFile(resolve(reportDir,'desempenho.json'),JSON.stringify(stats,null,2));console.log('Desempenho auditado:',JSON.stringify(stats));assert(stats.max_ms<2000);
  });
 } finally {
  if(bulk.length)await db.query('DELETE FROM "OCORRENCIA_ANIMAL" WHERE id_ocorrencia=ANY($1::int[])',[bulk]);
  for(const item of occs)await request('/ocorrencias/'+item.id,{method:'DELETE',token:item.user.token}).catch(()=>{});
  if(users.length)await db.query('DELETE FROM "USUARIO" WHERE id_usuario=ANY($1::int[])',[users]);
  await db.end();await monitor.end();s3.destroy();
 }
});
