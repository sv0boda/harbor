import {derivePin,newSalt,prove,parseAmount,formatAmount} from './pin-client.mjs';
import {renderAlpha,parseWalletImport} from './alpha-view.mjs';
const base=new URL('.',import.meta.url).pathname,root=document.querySelector('#view'),status=document.querySelector('#status'),dialog=document.querySelector('#review');
let state=null,busy=false,frozen=null,timer=null,requestSequence=0;
function tell(message,error=false){status.textContent=message;status.className=error?'status err':'status';}
function draw(){const old=root.querySelector('#send');const draft=old&&root.dataset.network===state.network?{to:old.elements.namedItem('to').value,amount:old.elements.namedItem('amount').value}:null;renderAlpha(root,{...state,busy:busy||state.busy},(op,data)=>void perform(op,data));if(draft){const form=root.querySelector('#send');if(form){form.elements.namedItem('to').value=draft.to;form.elements.namedItem('amount').value=draft.amount;}}root.dataset.network=state.network;document.querySelector('#ship').textContent=state.ship;}
async function request(action){
 const sequence=++requestSequence;
 let r;try{r=await fetch(base+'api/'+(action?'action':'state'),{method:action?'POST':'GET',credentials:'same-origin',cache:'no-store',headers:action?{'content-type':'application/json','x-harbor':'1'}:{},...(action?{body:JSON.stringify({...action,expectedNetwork:state.network})}:{})});}catch(error){if(sequence!==requestSequence)return {ignored:true};throw error;}
 if(sequence!==requestSequence)return {ignored:true};
 if(r.status===401){location.assign('/~/login?redirect='+encodeURIComponent(base));throw new Error('Sign in to your ship');}
 const body=await r.json();if(sequence!==requestSequence)return {ignored:true};if(body.state)state=body.state;
 if(!r.ok||!body.ok)throw new Error(body.error||'Request rejected');
 return body;
}
function closeReview(){dialog.close();frozen=null;document.querySelector('#approval-pin').value='';}
function showReview(){
 frozen={...state.challenge,salt:state.salt,ship:state.ship,network:state.network};
 document.querySelector('#review-text').textContent=`${frozen.network}: send ${formatAmount(frozen.amount)} OCT to ${frozen.to}. Fee ${formatAmount(frozen.fee)} OCT. Nonce ${frozen.txNonce}. Approval signs and submits this exact payment.`;
 dialog.showModal();document.querySelector('#approval-pin').focus();
}
function schedule(){
 clearTimeout(timer);
 if(state.busy||state.outbox.some(x=>x.phase==='ready'||x.phase==='sending'))timer=setTimeout(async()=>{
  if(busy||dialog.open){schedule();return;}
  try{const reply=await request();if(!reply.ignored){draw();if(state.error)tell(state.error,true);}}catch{tell('Unable to refresh. Check saved payment status before sending again.',true);}
  schedule();
 },1000);
}
async function perform(op,data){
 if(busy)return;busy=true;for(const b of root.querySelectorAll('button,select'))b.disabled=true;tell('Working…');
 try{
  let action;
  if(op==='import'){
   if(data.pin!==data.confirmPin)throw new Error('PINs do not match');
   const parsed=parseWalletImport(data.privateKey);
   if(!/^oct[1-9A-HJ-NP-Za-km-z]{44}$/.test(data.address.trim()))throw new Error('Enter the matching wallet address beginning with oct.');
   const salt=newSalt(),verifier=await derivePin(data.pin,salt,state.ship);
   action={op,privateKey:parsed.privateKey,address:data.address.trim(),salt,verifier};
   data.privateKey='';data.pin='';data.confirmPin='';
  }else if(op==='prepare') action={op,id:crypto.randomUUID(),to:data.to.trim(),amount:parseAmount(data.amount)};
  else action={op,...data};
  await request(action);action=null;
  if(op==='prepare')showReview();
  tell(op==='network'?`Switched to ${state.network==='devnet'?'Devnet':'Mainnet alpha'}. ${state.imported?'Refresh to check this account.':'Import a separate wallet for this network.'}`:op==='import'?'Imported on your ship. Refresh to check the account.':op==='prepare'?'Review recipient, amount, fee and network.':'Checking Octra…');
 }catch(e){tell(e.message,true);}finally{if(data){data.privateKey='';data.pin='';data.confirmPin='';}busy=false;draw();schedule();}
}
document.querySelector('#approval').addEventListener('submit',async e=>{
 e.preventDefault();if(busy||!frozen)return;busy=true;document.querySelector('#approve').disabled=true;
 let pin=document.querySelector('#approval-pin').value;document.querySelector('#approval-pin').value='';
 try{
  const proof=await prove(pin,frozen.salt,frozen.message,frozen.ship);pin='';
  await request({op:'approve',nonce:frozen.nonce,proof});closeReview();tell('Signed payment saved on your ship. Waiting for submission; this is not confirmation.');
 }catch(e){closeReview();tell(e.message,true);}finally{pin='';busy=false;document.querySelector('#approve').disabled=false;draw();schedule();}
});
document.querySelector('#cancel').addEventListener('click',()=>{if(!busy)closeReview();});
dialog.addEventListener('cancel',e=>{if(busy)e.preventDefault();else{frozen=null;document.querySelector('#approval-pin').value='';}});
try{await request();draw();tell('Public-payment alpha · use a dedicated test wallet');schedule();}catch(e){tell(e.message,true);}
