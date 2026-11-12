import ts from 'typescript';
import {readFile,readdir,mkdir,writeFile} from 'node:fs/promises';
import {join,resolve} from 'node:path';
import assert from 'node:assert/strict';
const target=resolve('../evidencias/auditoria-2026-11-11');await mkdir(target,{recursive:true});
async function files(dir){const result=[];for(const e of await readdir(dir,{withFileTypes:true})){const p=join(dir,e.name);if(e.isDirectory())result.push(...await files(p));else if(p.endsWith('.ts'))result.push(p);}return result;}
function decorators(node){return (ts.canHaveDecorators(node)?ts.getDecorators(node):[])?.map(d=>{
 const e=d.expression;return {name:ts.isCallExpression(e)?e.expression.getText():e.getText(),args:ts.isCallExpression(e)?e.arguments:[],text:e.getText()};
})??[];}
const routes=[];
for(const file of await files('src')){
 const tree=ts.createSourceFile(file,await readFile(file,'utf8'),ts.ScriptTarget.Latest,true);
 for(const c of tree.statements.filter(ts.isClassDeclaration)){
  const ds=decorators(c),controller=ds.find(d=>d.name==='Controller');if(!controller)continue;
  const prefix=controller.args[0]?.text??'';
  for(const method of c.members.filter(ts.isMethodDeclaration)){
   const ms=decorators(method),verb=ms.find(d=>['Get','Post','Put','Patch','Delete','Sse'].includes(d.name));if(!verb)continue;
   const path=('/'+prefix+'/'+(verb.args[0]?.text??'')).replace(/\/+$/,'').replace(/\/+/g,'/')||'/';
   routes.push({route:(verb.name==='Sse'?'GET':verb.name.toUpperCase())+' '+path,
    autenticacao:[...ds,...ms].some(d=>d.name==='UseGuards'&&d.text.includes('SessaoGuard')),arquivo:file,classe:c.name.text,metodo:method.name.getText()});
  }
 }
}
const expected=[
 'POST /auth/login','POST /auth/logout','POST /usuarios/cadastro','GET /usuarios/me','PATCH /usuarios/me',
 'GET /ocorrencias/eventos','GET /ocorrencias','GET /ocorrencias/minhas','GET /ocorrencias/:id/editar','GET /ocorrencias/:id',
 'POST /ocorrencias','PUT /ocorrencias/:id','PATCH /ocorrencias/:id/status','DELETE /ocorrencias/:id',
 'GET /fotos/:key','GET /correspondencias','GET /correspondencias/:id','POST /correspondencias/:id/notificacao-emitida',
 'GET /localizacoes/radar','GET /mapa/:z/:x/:y','GET /contatos/:id'];
assert.deepEqual(routes.map(x=>x.route).sort(),expected.sort());
const publicRoutes=new Set(['POST /auth/login','POST /usuarios/cadastro','GET /fotos/:key','GET /mapa/:z/:x/:y']);
for(const r of routes)assert.equal(r.autenticacao,!publicRoutes.has(r.route),r.route);
const app=await readFile('../app/lib/main.dart','utf8');
const paths=[...app.matchAll(/path:\s*'([^']+)'/g)].map(m=>m[1]);
assert.deepEqual(paths.sort(),['/iniciando','/login','/cadastro','/galeria','/radar','/registrar','/registrar/:id','/ocorrencia/:id','/gerenciar','/perfil','/correspondencia/:id'].sort());
const domain=(await readFile('../app/lib/domain/entidades.dart','utf8'))+'\n'+(await readFile('../app/lib/domain/modelo.dart','utf8'));
const classes=[...domain.matchAll(/class\s+(\w+)/g)].map(m=>m[1]);
for(const name of ['Usuario','OcorrenciaAnimal','Busca','Contato','Foto','Localizacao','Cidade','Animal','MensagemWhatsapp','Especie'])assert(classes.includes(name),name);
const source=JSON.parse(await readFile('../docs/MASTER.json','utf8'));
await writeFile(join(target,'escopo-e-acesso.json'),JSON.stringify({master_sha256:source.sha256,rotas_api:routes,rotas_flutter:paths,classes_dominio:classes,
 nota:'21 endpoints previstos; 11 caminhos para nove janelas, uma operacao de edicao e estado de carga. Metadados de rotas nao substituem os testes de autorizacao e de comportamento.'},null,2));
console.log('Escopo conferido: 21 endpoints, nove janelas, classes do diagrama e autenticação das rotas. Sem rotas adicionais de negócio.');
