-- Yazi configuration file for plugin startup.
--
-- For more information, visit https://yazi-rs.github.io/docs/plugins/overview.

require('auto-layout'):setup()
if not os.getenv('ZELLIJ') then
  require('full-border'):setup({ type = ui.Border.ROUNDED })
end
require('git'):setup()
require('starship'):setup()
