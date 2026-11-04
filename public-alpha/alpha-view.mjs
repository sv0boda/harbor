import { formatAmount } from './pin-client.mjs';
import { renderNetworkPicker } from './network-picker.mjs';

const CUSTODY =
  'Custody trust notice: this host (and installed apps) can access your keys. ' +
  'Keep your original backup safe, and use an exclusive, minimally funded test wallet.';

// Normalize supported exports locally; Gall independently derives and matches the address.
export function parseWalletImport(input) {
  if (typeof input !== 'string' || input.length > 4096) throw new Error('Use a wallet file or key up to 4 KiB.');
  const text=input.trim();
  const normalize=value=>{
    if(typeof value!=='string')throw new Error('The export has no supported private key.');
    const key=value.trim();
    if(/^[0-9a-fA-F]{64}$/.test(key))return btoa(String.fromCharCode(...key.match(/../g).map(x=>parseInt(x,16))));
    if(!/^[A-Za-z0-9+/]{43}=$/.test(key))throw new Error('Paste the 32-byte Base64 or hexadecimal key, or upload the original wallet export.');
    const bytes=atob(key);
    if(bytes.length!==32||btoa(bytes)!==key)throw new Error('The private key encoding is invalid.');
    return key;
  };
  if(!text.startsWith('{'))return {privateKey:normalize(text),address:''};
  let j;try{j=JSON.parse(text);}catch{throw new Error('Invalid wallet JSON. Upload the original export file.');}
  if(!j||typeof j!=='object'||Array.isArray(j))throw new Error('Invalid wallet export.');
  const addresses=['addr','address'].filter(k=>Object.hasOwn(j,k)).map(k=>j[k]);
  if(addresses.some(a=>typeof a!=='string'||!/^oct[1-9A-HJ-NP-Za-km-z]{44}$/.test(a))||new Set(addresses).size>1)throw new Error('The export contains an invalid or conflicting wallet address.');
  const keys=['priv','private_key_b64','private_key_hex'].filter(k=>Object.hasOwn(j,k)).map(k=>normalize(j[k]));
  if(Object.hasOwn(j,'keyPair')){
    const pair=j.keyPair;
    if(!pair||typeof pair!=='object'||typeof pair.secretKey!=='string'||typeof pair.publicKey!=='string'||!(/^[0-9a-fA-F]{128}$/).test(pair.secretKey)||!(/^[0-9a-fA-F]{64}$/).test(pair.publicKey))throw new Error('The export has an invalid keyPair.');
    if(pair.secretKey.slice(64).toLowerCase()!==pair.publicKey.toLowerCase())throw new Error('The export keyPair fields do not match.');
    keys.push(normalize(pair.secretKey.slice(0,64)));
  }
  if(!keys.length)throw new Error('Supported exports contain keyPair, private_key_b64/private_key_hex, or priv.');
  if(new Set(keys).size!==1)throw new Error('The export contains conflicting wallet keys.');
  return {privateKey:keys[0],address:addresses[0]||''};
}

export function renderAlpha(root, state, onAction) {
  root.textContent = '';
  if (Array.isArray(state.networks)) root.appendChild(renderNetworkPicker(state, onAction));

  const currentAvailable = state.networks?.find(n => n.network === state.network)?.available !== false;
  const panelState = currentAvailable ? state : { ...state, busy: true };
  if (!currentAvailable) {
    const unavailable = document.createElement('p');
    unavailable.textContent = 'This network is not available on this ship. Select another network to continue.';
    root.appendChild(unavailable);
  }

  const panel = document.createElement('section');
  panel.className = 'panel';
  if (panelState.error) {
    const err = document.createElement('p');
    err.className = 'muted';
    err.textContent = panelState.error;
    panel.appendChild(err);
  }
  if (!panelState.imported) {
    panel.appendChild(importForm(panelState, onAction));
  } else {
    const notice = document.createElement('p');
    notice.className = 'muted';
    notice.textContent = CUSTODY;
    panel.appendChild(notice);
    const status = document.createElement('div');
    status.className = 'row';
    status.textContent = [
      panelState.address, panelState.network,
      panelState.balance != null ? formatAmount(panelState.balance) : 'Refresh to read balance',
      panelState.syncedAt ? 'synced ' + new Date(panelState.syncedAt * 1000).toISOString() : '',
    ].filter(Boolean).join(' · ');
    panel.appendChild(status);
    panel.appendChild(sendForm(panelState, onAction));
    panel.appendChild(outbox(panelState, onAction));
  }
  const refresh = document.createElement('button');
  refresh.className = 'primary';
  refresh.textContent = 'Refresh';
  refresh.disabled = panelState.busy || !panelState.imported;
  refresh.addEventListener('click', () => {
    if (panelState.busy) return;
    onAction('sync', {});
  });
  panel.appendChild(refresh);
  root.appendChild(panel);
}

function importForm(state, onAction) {
  const form = document.createElement('form');
  form.id = 'import';
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    if (state.busy) return;
    onAction('import', {
      privateKey: form.elements.namedItem('privateKey').value, address: form.elements.namedItem('address').value,
      pin: form.elements.namedItem('pin').value, confirmPin: form.elements.namedItem('confirmPin').value,
    });
    form.elements.namedItem('privateKey').value = form.elements.namedItem('pin').value = form.elements.namedItem('confirmPin').value = '';
  });
  const info=document.createElement('p');info.className='muted';info.textContent=CUSTODY;
  const problem=document.createElement('p');problem.className='status err';problem.setAttribute('role','alert');
  const file = document.createElement('input');
  file.type = 'file';
  file.id = 'import-file';
  file.accept = 'application/json,text/plain';
  file.addEventListener('change', async () => {
    const f = file.files && file.files[0];
    if (!f) return;
    try {
      if (f.size > 4096) throw new Error('file too large');
      const parsed=parseWalletImport(await f.text());
      problem.textContent='';
      form.elements.namedItem('privateKey').value=parsed.privateKey;
      form.elements.namedItem('address').value=parsed.address;
    } catch(e) {
      form.elements.namedItem('privateKey').value='';form.elements.namedItem('address').value='';
      problem.textContent=e.message==='file too large'?'Use a wallet export up to 4 KiB.':e.message;
    }
    file.value = '';
  });
  const key = document.createElement('textarea');
  key.name = 'privateKey';
  key.autocomplete = 'off';
  key.placeholder = 'Base64 or 64-character hexadecimal private key';key.required=true;key.maxLength=128;key.setAttribute('aria-label','Private key');
  const address = document.createElement('input');
  address.name = 'address';
  address.required = true;address.setAttribute('aria-label','Expected Octra address');address.placeholder='Expected Octra address';address.maxLength=47;
  const pin = document.createElement('input');
  pin.name = 'pin';pin.placeholder='PIN (4–6 digits)';
  pin.type = 'password';
  pin.maxLength = 6;pin.minLength=4;pin.required=true;pin.inputMode='numeric';pin.autocomplete='new-password';pin.setAttribute('aria-label','PIN');
  pin.pattern = '[0-9]{4,6}';
  const confirmPin = document.createElement('input');
  confirmPin.name = 'confirmPin';confirmPin.placeholder='Confirm PIN';
  confirmPin.type = 'password';
  confirmPin.maxLength = 6;confirmPin.minLength=4;confirmPin.required=true;confirmPin.inputMode='numeric';confirmPin.autocomplete='new-password';confirmPin.setAttribute('aria-label','Confirm PIN');
  confirmPin.pattern = '[0-9]{4,6}';
  const submit = document.createElement('button');
  submit.type = 'submit';
  submit.className = 'primary';
  submit.textContent = 'Import';
  submit.disabled = state.busy;
  const help=document.createElement('p');help.className='muted';help.textContent='Upload your Octra wallet JSON to fill the key and address, or enter both below. The address must match the key.';
  form.append(info, help, problem);
  for(const [input,text] of [[file,'Wallet export file'],[key,'Private key'],[address,'Wallet address (oct…)'],[pin,'Payment PIN (4–6 digits)'],[confirmPin,'Confirm PIN']]){const label=document.createElement('label');label.textContent=text;input.id=input.id||'import-'+input.name;label.htmlFor=input.id;input.setAttribute('aria-label',text);form.append(label,input);}
  form.append(submit);
  return form;
}

function sendForm(state, onAction) {
  const form = document.createElement('form');
  form.id = 'send';
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    if (state.busy) return;
    onAction('prepare', { to: form.elements.namedItem('to').value, amount: form.elements.namedItem('amount').value });
  });
  const to = document.createElement('input');
  to.name = 'to';
  to.required = true;to.maxLength=47;to.placeholder='Recipient Octra address';to.setAttribute('aria-label','Recipient');
  const amount = document.createElement('input');
  amount.name = 'amount';
  amount.required = true;amount.placeholder='Amount in OCT';amount.setAttribute('aria-label','Amount');amount.inputMode='decimal';
  const submit = document.createElement('button');
  submit.type = 'submit';
  submit.className = 'primary';
  submit.textContent = 'Review';
  submit.disabled = state.busy || state.blocking || state.fee==null || !state.syncedAt;
  form.append(to, amount, submit);
  return form;
}

function outbox(state, onAction) {
  const box = document.createElement('div');
  box.className = 'row';
  for (const t of state.outbox || []) {
    const line = document.createElement('div');
    line.className = 'row';
    line.textContent = t.hash + ' → ' + t.to + ' ' + formatAmount(t.amount) +
      ' (fee ' + formatAmount(t.fee) + ', nonce ' + t.nonce + ', ' + t.phase +
      ', attempts ' + t.attempts + ')';
    if (t.phase !== 'ready' && t.phase !== 'confirmed') {
      const btn = document.createElement('button');
      btn.textContent = 'Reconcile';
      btn.disabled = state.busy;
      btn.addEventListener('click', () => {
        if (state.busy) return;
        onAction('reconcile', { hash: t.hash });
      });
      line.appendChild(btn);
    }
    box.appendChild(line);
  }
  if (state.blocking) {
    const note = document.createElement('p');
    note.className = 'muted';
    note.textContent = 'Further payments paused; check status.';
    box.appendChild(note);
  }
  return box;
}
