import{_ as e,o,c as a,V as i}from"./chunks/framework.8bdd1e96.js";const p=JSON.parse('{"title":"Configuration","description":"","frontmatter":{},"headers":[],"relativePath":"config.md","filePath":"config.md","lastUpdated":1697738197000}'),t={name:"config.md"},n=i('<h1 id="configuration" tabindex="-1">Configuration <a class="header-anchor" href="#configuration" aria-label="Permalink to &quot;Configuration&quot;">​</a></h1><h2 id="configuration-file" tabindex="-1">Configuration File <a class="header-anchor" href="#configuration-file" aria-label="Permalink to &quot;Configuration File&quot;">​</a></h2><p>Bootware uses the <a href="https://yaml.org/" target="_blank" rel="noreferrer">YAML</a> language for its configuration file. Bootware uses the first available path option as its configuration file.</p><ul><li><code>&lt;path&gt;</code> (argument to -c/--config command line flag)</li><li><code>bootware.yaml</code> (in the current directory)</li><li><code>BOOTWARE_CONFIG</code> (environment variable)</li><li><code>~/.bootware/config.yaml</code> (in the home directory)</li></ul><p>Bootware can generate a default configuration file in the user&#39;s home directory, by executing <code>bootware config</code>.</p><h2 id="environment-variables" tabindex="-1">Environment Variables <a class="header-anchor" href="#environment-variables" aria-label="Permalink to &quot;Environment Variables&quot;">​</a></h2><p>Several Bootware options can also be specified with environment variables.</p><ul><li><code>BOOTWARE_CONFIG</code>: Set the configuration file path</li><li><code>BOOTWARE_NOPASSWD</code>: Assume passwordless sudo</li><li><code>BOOTWARE_NOSETUP</code>: Skip Ansible install and system setup</li><li><code>BOOTWARE_PLAYBOOK</code>: Set Ansible playbook name</li><li><code>BOOTWARE_SKIP</code>: Set skip tags for Ansible roles</li><li><code>BOOTWARE_TAGS</code>: Set tags for Ansible roles</li><li><code>BOOTWARE_URL</code>: Set location of Ansible repository</li></ul><h2 id="command-line" tabindex="-1">Command Line <a class="header-anchor" href="#command-line" aria-label="Permalink to &quot;Command Line&quot;">​</a></h2><p>Many Bootware features can controlled directly fron the command line. For a list of options, execute <code>bootware --help</code> or <code>bootware &lt;subcommand&gt; --help</code> for a subcommand&#39;s specific options.</p>',10),r=[n];function l(c,s,d,f,u,m){return o(),a("div",null,r)}const _=e(t,[["render",l]]);export{p as __pageData,_ as default};