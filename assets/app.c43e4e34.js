import{C as o,a5 as i,a6 as p,a7 as u,a8 as c,a9 as l,aa as f,ab as d,ac as m,ad as g,ae as h,X as A,x as P,u as v,U as y,e as C,af as _,ag as b,ah as w,ai as x}from"./chunks/framework.6c35cc06.js";import{t as D}from"./chunks/theme.59a473ba.js";function r(e){if(e.extends){const a=r(e.extends);return{...a,...e,async enhanceApp(t){a.enhanceApp&&await a.enhanceApp(t),e.enhanceApp&&await e.enhanceApp(t)}}}return e}const s=r(D),E=P({name:"VitePressApp",setup(){const{site:e}=v();return y(()=>{C(()=>{document.documentElement.lang=e.value.lang,document.documentElement.dir=e.value.dir})}),_(),b(),w(),s.setup&&s.setup(),()=>x(s.Layout)}});async function R(){const e=T(),a=O();a.provide(p,e);const t=u(e.route);return a.provide(c,t),a.component("Content",l),a.component("ClientOnly",f),Object.defineProperties(a.config.globalProperties,{$frontmatter:{get(){return t.frontmatter.value}},$params:{get(){return t.page.value.params}}}),s.enhanceApp&&await s.enhanceApp({app:a,router:e,siteData:d}),{app:a,router:e,data:t}}function O(){return m(E)}function T(){let e=o,a;return g(t=>{let n=h(t);return n?(e&&(a=n),(e||a===n)&&(n=n.replace(/\.js$/,".lean.js")),o&&(e=!1),A(()=>import(n),[])):null},s.NotFound)}o&&R().then(({app:e,router:a,data:t})=>{a.go().then(()=>{i(a.route,t.site),e.mount("#app")})});export{R as createApp};