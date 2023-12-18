// Mozilla user preferences for Firefox.
//
// To view all possible options, visit about:config in the browser.

// Disable Firefox studies.
user_pref("app.shield.optoutstudies.enabled", false);
// Disable saving information entered in web page forms and search bar.
user_pref("browser.formfill.enable", false);
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
// Set browser theme to Solarized-Light,
// https://addons.mozilla.org/firefox/addon/solarized-light, by dustractor.
user_pref("extensions.activeThemeID", "{71864fba-a0ac-47f5-a514-e5f3378b9c12}");
// Remove Pocket from Firefox.
user_pref("extensions.pocket.enabled", false);
// Disable autofilling addresses.
user_pref("extensions.formautofill.addresses.enabled", false);
// Disable autofilling credit cards.
user_pref("extensions.formautofill.creditCards.enabled", false);
// Disable audio and video autoplay.
user_pref("media.autoplay.blocking_policy", 2);
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
// Block trackers from following browsing habits.
user_pref("privacy.trackingprotection.enabled", true);
// Disable syncing browsing history.
user_pref("services.sync.engine.history", false);
// Disable syncing site passwords.
user_pref("services.sync.engine.passwords", false);
// Prevent alt key from popping up the menu bar.
user_pref("ui.key.menuAccessKeyFocuses", false);
