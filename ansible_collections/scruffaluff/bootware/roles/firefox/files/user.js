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
// Disable saving information entered in web page forms and search bar.
user_pref("browser.formfill.enable", false);
// Remove news stories recommendations from homepage.
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
// Remove top sites recommendations from homepage.
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
// Remove Pocket recommendations from homepage.
user_pref(
  "browser.newtabpage.activity-stream.section.highlights.includePocket",
  false
);
// Disable detaching tab to a new window.
user_pref("browser.tabs.allowTabDetach", false);
// Show bookmarks bar in toolbar.
user_pref("browser.toolbars.bookmarks.visibility", "always");
// Disable automatic translation popups.
user_pref("browser.translations.automaticallyPopup", false);
// Disable search engine suggestions in search bar.
user_pref("browser.urlbar.suggest.engines", false);
// Disable history suggestions in search bar.
user_pref("browser.urlbar.suggest.history", false);
// Disable partner suggestions in search bar.
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
// Disable sponsored suggestions in search bar.
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
// Don't warning on quitting Firefox.
user_pref("browser.warnOnQuit", false);
// Don't warning on quitting Firefox.
user_pref("browser.warnOnQuitShortcut", false);
// Enable HTTPS only mode.
user_pref("dom.security.https_only_mode", true);
// Remove Pocket extension from Firefox.
user_pref("extensions.pocket.enabled", false);
// Disable autofilling addresses.
user_pref("extensions.formautofill.addresses.enabled", false);
// Disable autofilling credit cards.
user_pref("extensions.formautofill.creditCards.enabled", false);
// Disable audio and video autoplay.
user_pref("media.autoplay.blocking_policy", 2);
// Allow DRM protected content to be played.
user_pref("media.eme.enabled", true);
// Prevent sites from asking to send notifications.
user_pref("permissions.default.desktop-notification", 2);
// Prevent sites from asking for location.
user_pref("permissions.default.geo", 2);
// Prevent sites from asking to connect to virtual reality devices.
user_pref("permissions.default.xr", 2);
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
