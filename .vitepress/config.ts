// VitePress documentation configuration file.
//
// This configuration uses the default VitePress theme, whose details can be
// found at https://vitepress.dev/reference/default-theme-config. For more
// information on VitePress configuration, visit
// https://vitepress.dev/reference/site-config.

import { defineConfig } from "vitepress";

export default defineConfig({
  base: "/bootware/",
  description: "Shell scripts for bootstrapping computers with Ansible.",
  lastUpdated: true,
  outDir: "site",
  srcDir: "docs",
  themeConfig: {
    aside: false,
    footer: {
      message: "Released under the MIT License.",
      copyright: "Copyright © 2021-Present Macklan Weinstein",
    },
    nav: [
      { text: "Home", link: "/" },
      { text: "Install", link: "/install" },
      { text: "Software", link: "/software" },
      { text: "Config", link: "/config" },
    ],
    search: {
      provider: "local",
    },
    socialLinks: [
      { icon: "github", link: "https://github.com/scruffaluff/bootware" },
    ],
  },
  title: "Bootware",
});
