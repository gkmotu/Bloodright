import { createGame, move, pickup, useItem, terrainAt } from './engine/core.js';

let content;
let game;
let selectedTerrain = 0;
let selectedItem = 0;
let brushId;
let placingStart = false;
const $ = s => document.querySelector(s);
const $$ = s => [...document.querySelectorAll(s)];

async function load() {
  const disk = await fetch('content/published/content.json').then(r => r.json());
  const draft = localStorage.getItem('bloodright.published');
  content = draft ? JSON.parse(draft) : disk;
  wireNavigation(); wireActions(); renderEditors(); startGame();
}

function wireNavigation() {
  $$('[data-view]').forEach(b => b.onclick = () => show(b.dataset.view));
  $('#enter').onclick = () => show('game');
}
function show(id) {
  $$('.view').forEach(v => v.classList.toggle('active', v.id === id));
  $$('[data-view]').forEach(b => b.classList.toggle('active', b.dataset.view === id));
  if (id === 'game') renderGame();
}
function startGame() { game = createGame(content); renderGame(); }
function act(action) { action(); renderGame(); }
function wireActions() {
  $$('[data-move]').forEach(b => b.onclick = () => { const [x,y]=b.dataset.move.split(',').map(Number); act(()=>move(game,x,y)); });
  $('[data-action="pickup"]').onclick = () => act(()=>pickup(game));
  $$('.publish').forEach(b => b.onclick = publishDraft);
  $('#add-terrain').onclick = () => { content.terrain.push({id:'varenza.terrain.new',name:'New Terrain',glyph:'·',color:'#aaaaaa',walkable:true,blocksSight:false,description:''}); selectedTerrain=content.terrain.length-1; renderEditors(); };
  $('#add-item').onclick = () => { content.items.push({id:'varenza.item.new',name:'New Item',glyph:'?',color:'#d5c6a1',category:'misc',description:'',effect:{kind:'none',amount:0}}); selectedItem=content.items.length-1; renderEditors(); };
  $('#place-start').onclick = () => { placingStart=true; toast('Click a map tile to place the hero.'); };
  addEventListener('keydown', e => {
    if (!$('#game').classList.contains('active') || ['INPUT','TEXTAREA','SELECT'].includes(e.target.tagName)) return;
    const dirs={ArrowUp:[0,-1],w:[0,-1],ArrowDown:[0,1],s:[0,1],ArrowLeft:[-1,0],a:[-1,0],ArrowRight:[1,0],d:[1,0]};
    if (dirs[e.key]) { e.preventDefault(); act(()=>move(game,...dirs[e.key])); }
    else if (e.key.toLowerCase()==='g') act(()=>pickup(game));
    else if (e.key.toLowerCase()==='r') startGame();
  });
}

function renderGame() {
  if (!game) return;
  const el=$('#game-map'); el.style.setProperty('--cols',game.map.width); el.innerHTML='';
  for(let y=0;y<game.map.height;y++) for(let x=0;x<game.map.width;x++) {
    const terrain=terrainAt(game,x,y), tile=document.createElement('span'); tile.className='tile'; tile.textContent=terrain.glyph; tile.style.color=terrain.color; tile.title=terrain.name;
    const item=game.groundItems.find(i=>i.x===x&&i.y===y);
    if(item){const def=game.content.itemById[item.itemId];tile.classList.add('item');tile.dataset.itemGlyph=def.glyph;tile.style.setProperty('--item-color',def.color);tile.title=def.name;}
    if(game.player.x===x&&game.player.y===y){tile.classList.remove('item');tile.classList.add('player');tile.title='You';}
    el.append(tile);
  }
  $('#hp-bar').style.width=`${game.player.hp/game.player.maxHp*100}%`; $('#stats').textContent=`Health ${game.player.hp}/${game.player.maxHp} · Turn ${game.turn}`;
  const inv=$('#inventory'); inv.innerHTML=game.player.inventory.length?'':'<span class="empty-note">Empty</span>';
  game.player.inventory.forEach((id,n)=>{const item=game.content.itemById[id], b=document.createElement('button');b.textContent=`${item.glyph} ${item.name}`;b.title=item.description;b.onclick=()=>act(()=>useItem(game,n));inv.append(b);});
  $('#messages').innerHTML=game.messages.slice(-4).map(m=>`<div>› ${escapeHtml(m)}</div>`).join('');
}

function renderEditors(){ renderTerrain(); renderItems(); renderMapEditor(); }
function renderTerrain(){
  const list=$('#terrain-list');list.innerHTML='';content.terrain.forEach((t,n)=>{const b=document.createElement('button');b.textContent=`${t.glyph}  ${t.name}`;b.classList.toggle('selected',n===selectedTerrain);b.onclick=()=>{selectedTerrain=n;renderTerrain()};list.append(b)});
  const t=content.terrain[selectedTerrain]; $('#terrain-form').innerHTML=`${field('Name','name',t.name)}${field('Stable ID','id',t.id)}${field('Glyph','glyph',t.glyph)}${field('Color','color',t.color,'color')}${check('Walkable','walkable',t.walkable)}${check('Blocks sight','blocksSight',t.blocksSight)}${field('Description','description',t.description,'textarea','wide')}`; bindForm($('#terrain-form'),t,renderEditors);
}
function renderItems(){
  const list=$('#item-list');list.innerHTML='';content.items.forEach((it,n)=>{const b=document.createElement('button');b.textContent=`${it.glyph}  ${it.name}`;b.classList.toggle('selected',n===selectedItem);b.onclick=()=>{selectedItem=n;renderItems()};list.append(b)});
  const it=content.items[selectedItem]; $('#item-form').innerHTML=`${field('Name','name',it.name)}${field('Stable ID','id',it.id)}${field('Glyph','glyph',it.glyph)}${field('Color','color',it.color,'color')}${field('Category','category',it.category)}${field('Effect','effect.kind',it.effect?.kind??'none')}${field('Amount','effect.amount',it.effect?.amount??0,'number')}${field('Description','description',it.description,'textarea','wide')}`; bindForm($('#item-form'),it,renderEditors);
}
function renderMapEditor(){
  brushId ||= content.terrain[0].id; const palette=$('#palette');palette.innerHTML='';
  content.terrain.forEach(t=>{const b=document.createElement('button');b.classList.toggle('active',brushId===t.id);b.innerHTML=`<span class="glyph" style="--swatch:${t.color}">${escapeHtml(t.glyph)}</span>${escapeHtml(t.name)}`;b.onclick=()=>{brushId=t.id;renderMapEditor()};palette.append(b)});
  const map=content.maps[0], el=$('#editor-map');el.style.setProperty('--cols',map.width);el.innerHTML='';
  for(let y=0;y<map.height;y++)for(let x=0;x<map.width;x++){const ch=map.tiles[y][x],t=content.terrain.find(v=>v.id===map.legend[ch]),tile=document.createElement('span');tile.className='tile';if(map.playerStart.x===x&&map.playerStart.y===y)tile.classList.add('player');tile.textContent=t?.glyph??'?';tile.style.color=t?.color??'#f00';tile.oncontextmenu=e=>{e.preventDefault();map.playerStart={x,y};renderMapEditor()};tile.onclick=()=>paint(map,x,y);el.append(tile)}
}
function paint(map,x,y){if(placingStart){map.playerStart={x,y};placingStart=false;renderMapEditor();return}const terrain=content.terrain.find(t=>t.id===brushId);let ch=Object.keys(map.legend).find(k=>map.legend[k]===brushId);if(!ch){ch=terrain.glyph;if(map.legend[ch]&&map.legend[ch]!==brushId)ch=findFreeChar(map.legend);map.legend[ch]=brushId}map.tiles[y]=map.tiles[y].slice(0,x)+ch+map.tiles[y].slice(x+1);renderMapEditor()}
function findFreeChar(legend){for(const c of 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')if(!legend[c])return c;return '~'}
function field(label,name,value,type='text',cls=''){const input=type==='textarea'?`<textarea name="${name}">${escapeHtml(value)}</textarea>`:`<input name="${name}" type="${type}" value="${escapeHtml(value)}">`;return `<label class="${cls}">${label}${input}</label>`}
function check(label,name,value){return `<label>${label}<input name="${name}" type="checkbox" ${value?'checked':''}></label>`}
function bindForm(form,obj,rerender){form.onchange=e=>{let value=e.target.type==='checkbox'?e.target.checked:e.target.type==='number'?Number(e.target.value):e.target.value;const path=e.target.name.split('.');if(path.length===2){obj[path[0]]??={};obj[path[0]][path[1]]=value}else obj[path[0]]=value;rerender()}}
function validateDraft(){const errors=[],ids=new Set();for(const x of [...content.terrain,...content.items,...content.maps]){if(!x.id||ids.has(x.id))errors.push(`Missing or duplicate ID: ${x.id}`);ids.add(x.id)}const terrains=new Set(content.terrain.map(x=>x.id));for(const m of content.maps)for(const id of Object.values(m.legend))if(!terrains.has(id))errors.push(`Map references missing terrain: ${id}`);return errors}
function publishDraft(){const errors=validateDraft();if(errors.length){toast(errors[0],true);return}content={...content,schemaVersion:1,publishedAt:new Date().toISOString()};localStorage.setItem('bloodright.published',JSON.stringify(content));startGame();toast('Published. The game now uses this Varenza content.');}
function toast(message,error=false){const el=$('#toast');el.textContent=message;el.style.borderColor=error?'#ad4f4f':'';el.classList.add('show');setTimeout(()=>el.classList.remove('show'),2800)}
function escapeHtml(value){return String(value??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]))}
load().catch(err=>{document.body.innerHTML=`<pre>Could not begin Bloodright: ${escapeHtml(err.message)}</pre>`});
