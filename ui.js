'use strict';
(() => {
  const reduced = window.matchMedia('(prefers-reduced-motion: reduce)');
  const body = document.body;
  const progress = document.createElement('div');
  progress.className = 'reading-progress'; progress.setAttribute('aria-hidden','true'); body.prepend(progress);
  const top = document.createElement('button');
  top.type='button'; top.className='back-top'; top.textContent='↑'; top.title='Volver al inicio'; top.setAttribute('aria-label','Volver al inicio'); top.hidden=true;
  top.addEventListener('click',()=>{window.scrollTo({top:0,behavior:reduced.matches?'instant':'smooth'});document.querySelector('.header .brand')?.focus({preventScroll:true});}); body.append(top);
  let scheduled=false;
  function measure(){scheduled=false;const max=document.documentElement.scrollHeight-window.innerHeight;progress.style.transform='scaleX('+(max>0?Math.min(1,window.scrollY/max):0)+')';top.hidden=window.scrollY<600;document.querySelector('.header')?.classList.toggle('is-scrolled',window.scrollY>20);}
  window.addEventListener('scroll',()=>{if(!scheduled){scheduled=true;requestAnimationFrame(measure)}},{passive:true});
  window.addEventListener('resize',measure); measure();

  let paused=reduced.matches;
  const controls=[];
  function updateMotion(){body.classList.toggle('motion-paused',paused||reduced.matches);for(const button of controls){button.textContent=paused||reduced.matches?'Activar animaciones':'Pausar animaciones';button.setAttribute('aria-pressed',String(paused||reduced.matches));button.disabled=reduced.matches;button.title=reduced.matches?'Tu sistema tiene activado movimiento reducido':'';}}
  function motionControl(parent,className){if(!parent)return;const button=document.createElement('button');button.type='button';button.className=className;button.addEventListener('click',()=>{paused=!paused;updateMotion()});controls.push(button);parent.append(button);}
  motionControl(document.querySelector('.footer'),'motion-control');
  motionControl(document.querySelector('.cinema'),'scene-control');
  updateMotion();

  let observer;
  const targets=[...document.querySelectorAll('.paper,.mk-story>div,.steps li,.help-band,.cinema,.feature,.flux-end,.doc-card,.article-section')];
  function finishReveals(){observer?.disconnect();for(const node of targets)node.classList.remove('reveal-pending');}
  if(!reduced.matches && 'IntersectionObserver' in window){
    observer=new IntersectionObserver(entries=>{for(const entry of entries)if(entry.isIntersecting){entry.target.classList.remove('reveal-pending');observer.unobserve(entry.target)}},{threshold:.08});
    targets.forEach((node,i)=>{node.style.setProperty('--reveal-delay',(i%3)*80+'ms');node.classList.add('reveal-pending');observer.observe(node)});
  }
  reduced.addEventListener('change',()=>{if(reduced.matches)finishReveals();updateMotion()});
  window.addEventListener('beforeprint',finishReveals);

  const grid=document.querySelector('.doc-grid');
  if(grid){
    const form=document.createElement('div');form.className='doc-search';
    const label=document.createElement('label');label.htmlFor='guide-search';label.textContent='Encuentra una guía';
    const input=document.createElement('input');input.id='guide-search';input.type='search';input.placeholder='Instalación, privacidad, versiones…';input.autocomplete='off';
    const result=document.createElement('p');result.className='search-status';result.setAttribute('role','status');
    const cards=[...grid.querySelectorAll('.doc-card')];
    const normalize=text=>text.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();
    input.addEventListener('input',()=>{const query=normalize(input.value.trim());let count=0;for(const card of cards){card.hidden=!normalize(card.textContent).includes(query);if(!card.hidden){count++;card.classList.remove('reveal-pending')}}result.textContent=query?(count?count+(count===1?' guía encontrada.':' guías encontradas.'):'No hay coincidencias. Prueba con otra palabra.') : '';});
    form.append(label,input,result);grid.before(form);
  }
  if(location.pathname.endsWith('/faq.html')){
    for(const section of document.querySelectorAll('.article-section')){
      const heading=section.querySelector('h2'); if(!heading)continue;
      const details=document.createElement('details');details.className='faq-item';
      const summary=document.createElement('summary');summary.textContent=heading.textContent;details.append(summary);
      for(const node of [...section.children])if(node!==heading)details.append(node);
      section.replaceWith(details);
    }
  }
  const article=document.querySelector('.doc-layout article');
  if(article && document.querySelectorAll('.article-section').length>2){
    const nav=document.createElement('nav');nav.className='on-this-page';nav.setAttribute('aria-label','En esta página');
    const label=document.createElement('strong');label.textContent='En esta página';nav.append(label);
    document.querySelectorAll('.article-section h2').forEach((heading,i)=>{heading.id='section-'+(i+1);const a=document.createElement('a');a.href='#'+heading.id;a.textContent=heading.textContent;nav.append(a);});
    article.querySelector('h1').after(nav);
  }
  if(document.querySelector('#assets')){
    const helper=document.createElement('div');helper.className='checksum-helper';
    const label=document.createElement('p');label.textContent='Verifica el archivo descargado con PowerShell:';
    const code=document.createElement('code');code.textContent='Get-FileHash -Algorithm SHA256 ./archivo.apk';
    const copy=document.createElement('button');copy.type='button';copy.textContent='Copiar comando';
    const result=document.createElement('span');result.setAttribute('role','status');
    copy.addEventListener('click',async()=>{try{await navigator.clipboard.writeText(code.textContent);result.textContent='Copiado';}catch{result.textContent='Selecciona el comando para copiarlo.'}});
    helper.append(label,code,copy,result);document.querySelector('.release-panel').after(helper);
  }
  /* ── Mobile drawer ── */
  const menuBtns = document.querySelectorAll('.mobile-menu-btn');
  const headerNav = document.querySelector('.header nav');
  if (menuBtns.length && headerNav) {
    let overlay = document.querySelector('.nav-overlay');
    if (!overlay) {
      overlay = document.createElement('div');
      overlay.className = 'nav-overlay';
      document.body.appendChild(overlay);
    }
    if (!headerNav.querySelector('.nav-drawer-header')) {
      const drawerHead = document.createElement('div');
      drawerHead.className = 'nav-drawer-header';
      const brandClone = document.querySelector('.header .brand');
      if (brandClone) drawerHead.appendChild(brandClone.cloneNode(true));
      const closeBtn = document.createElement('button');
      closeBtn.type = 'button';
      closeBtn.className = 'nav-close-btn';
      closeBtn.setAttribute('aria-label', 'Cerrar menú');
      closeBtn.textContent = '✕';
      drawerHead.appendChild(closeBtn);
      headerNav.insertBefore(drawerHead, headerNav.firstChild);
      closeBtn.addEventListener('click', closeDrawer);
    }
    function openDrawer() {
      headerNav.classList.add('nav-open');
      overlay.style.display = 'block';
      requestAnimationFrame(() => overlay.style.opacity = '1');
      document.body.style.overflow = 'hidden';
      menuBtns.forEach(b => { b.classList.add('open'); b.setAttribute('aria-expanded', 'true'); });
    }
    function closeDrawer() {
      headerNav.classList.remove('nav-open');
      overlay.style.opacity = '0';
      document.body.style.overflow = '';
      menuBtns.forEach(b => { b.classList.remove('open'); b.setAttribute('aria-expanded', 'false'); });
      setTimeout(() => { overlay.style.display = ''; }, 300);
    }
    menuBtns.forEach(btn => {
      btn.setAttribute('aria-expanded', 'false');
      btn.addEventListener('click', () => headerNav.classList.contains('nav-open') ? closeDrawer() : openDrawer());
    });
    overlay.addEventListener('click', closeDrawer);
    document.addEventListener('keydown', e => { if (e.key === 'Escape' && headerNav.classList.contains('nav-open')) closeDrawer(); });
  }
})();

