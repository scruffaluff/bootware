// Mozilla user preferences for Firefox.
//
// To view all possible options, visit about:config in the browser.

// Disable Firefox studies.
user_pref("app.shield.optoutstudies.enabled", false);
// Remove warning when accessing configuration page.
user_pref("browser.aboutConfig.showWarning", false);
// Disable initial welcome page.
user_pref("browser.aboutwelcome.enabled", false);
// Enable enhanced tracking protection.
user_pref("browser.contentblocking.category", "strict");
// Hide Mozilla VPN recommendations.
user_pref("browser.contentblocking.report.hide_vpn_banner", true);
// Hide Firefox Lockwise recommendations.
user_pref("browser.contentblocking.report.lockwise.enabled", false);
// Hide Firefox Monitor recommendations.
user_pref("browser.contentblocking.report.monitor.enabled", false);
// Disable saving information entered in web page forms and search bar.
user_pref("browser.formfill.enable", false);
// Disable Firefox machine learning chat.
user_pref("browser.ml.chat.enabled", false);
// Disable Firefox machine learning chat shortcuts.
user_pref("browser.ml.chat.shortcuts", false);
// Disable Firefox machine learning chat sidebar.
user_pref("browser.ml.chat.sidebar", false);
// Disable Firefox machine learning.
user_pref("browser.ml.enabled", false);
// Remove news stories recommendations from homepage.
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
// Remove weather status recommendations from homepage.
user_pref("browser.newtabpage.activity-stream.feeds.weatherfeed", false);
// Disable Firefox telemetry.
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
// Remove top sites recommendations from homepage.
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
// Remove Pocket recommendations from homepage.
user_pref(
  "browser.newtabpage.activity-stream.section.highlights.includePocket",
  false
);
// Disable Firefox telemetry.
user_pref("browser.newtabpage.activity-stream.telemetry", false);
// Disable weather status suggestions in search bar.
user_pref("browser.newtabpage.activity-stream.showWeather", false);
// Disable weather status suggestions from system recommendations.
user_pref("browser.newtabpage.activity-stream.system.showWeather", false);
// Stay on current tab after opening link in new tab.
user_pref("browser.tabs.loadInBackground", true);
// Disable detaching tab to a new window.
user_pref("browser.tabs.allowTabDetach", false);
// Show bookmarks bar in toolbar.
user_pref("browser.toolbars.bookmarks.visibility", "always");
// Disable automatic translation popups.
user_pref("browser.translations.automaticallyPopup", false);
// Enable bookmarks suggestions in search bar.
user_pref("browser.urlbar.suggest.bookmark", true);
// Enable search engine suggestions in search bar.
user_pref("browser.urlbar.suggest.engines", true);
// Disable history suggestions in search bar.
user_pref("browser.urlbar.suggest.history", false);
// Disable open tab suggestions in search bar.
user_pref("browser.urlbar.suggest.openpage", true);
// Disable partner suggestions in search bar.
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
// Disable sponsored suggestions in search bar.
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
// Disable popular websites suggestions in search bar.
user_pref("browser.urlbar.suggest.topsites", false);
// Disable weather suggestions in search bar.
user_pref("browser.urlbar.suggest.weather", false);
// Don't warning on quitting Firefox.
user_pref("browser.warnOnQuit", false);
// Don't warning on quitting Firefox.
user_pref("browser.warnOnQuitShortcut", false);
// Disable Firefox health reporting.
user_pref("datareporting.healthreport.uploadEnabled", false);
// Disable Firefox data reporting.
user_pref("datareporting.policy.dataSubmissionEnabled", false);
// Disable Firefox website advertising preferences telemetry.
user_pref("dom.private-attribution.submission.enabled", false);
// Enable HTTPS only mode.
user_pref("dom.security.https_only_mode", true);
// Remove Pocket extension from Firefox.
user_pref("extensions.pocket.enabled", false);
// Disable autofilling addresses.
user_pref("extensions.formautofill.addresses.enabled", false);
// Disable autofilling credit cards.
user_pref("extensions.formautofill.creditCards.enabled", false);
// Disable notifications about webpages entering fullscreen mode.
user_pref("full-screen-api.warning.timeout", 0);
// Disable audio and video autoplay.
user_pref("media.autoplay.blocking_policy", 2);
// Disable touchpad history navigation when alt key is pressed.
user_pref("mousewheel.with_alt.action", 0);
// Disable touchpad zoom when control key is pressed.
user_pref("mousewheel.with_control.action", 0);
// Allow DRM protected content to be played.
user_pref("media.eme.enabled", true);
// Prevent "add application for mailto links" popup.
user_pref("network.protocol-handler.external.mailto", false);
// Prevent sites from asking to send notifications.
user_pref("permissions.default.desktop-notification", 2);
// Prevent sites from asking for location.
user_pref("permissions.default.geo", 2);
// Prevent sites from asking to connect to virtual reality devices.
user_pref("permissions.default.xr", 2);
// Clear downloads list on browser close.
user_pref("privacy.clearOnShutdown.downloads", true);
// Send sites do not track header in HTTP requests.
user_pref("privacy.donottrackheader.enabled", true);
// Send sites no consent message to selling personal information.
user_pref("privacy.globalprivacycontrol.enabled", true);
// Strip tracking querys from URLs.
user_pref("privacy.query_stripping.enabled", true);
// Strip tracking querys from URLs.
user_pref("privacy.query_stripping.enabled.pbmode", true);
// Prevent trackers from following browsing habits.
user_pref("privacy.trackingprotection.enabled", true);
// Prevent trackers from following browsing habits.
user_pref("privacy.trackingprotection.emailtracking.enabled", true);
// Prevent trackers from following browsing habits.
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
// Disable syncing browsing history.
user_pref("services.sync.engine.history", false);
// Disable syncing site passwords.
user_pref("services.sync.engine.passwords", false);
// Prevent Firefox from offering to save passwords.
user_pref("signon.autofillForms", false);
// Prevent Firefox from offering to save passwords.
user_pref("signon.generation.enabled", false);
// Prevent Firefox from offering to save passwords.
user_pref("signon.management.page.breach-alerts.enabled", false);
// Prevent Firefox from offering to save passwords.
user_pref("signon.rememberSignons", false);
// Prevent alt key from popping up the menu bar.
user_pref("ui.key.menuAccessKeyFocuses", false);
