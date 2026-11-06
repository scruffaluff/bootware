# Chrome

Ansible role that installs [Google Chrome](https://google.com/chrome) web
browser.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
chrome_policies:
  AIModeSettings: 1
  CreateThemesSettings: 2
  DevToolsGenAiSettings: 2
  HelpMeWriteSettings: 2
  GeminiSettings: 1
  GenAILocalFoundationalModelSettings: 1
  HistorySearchSettings: 2
  SearchContentSharingSettings: 1
  TabCompareSettings: 2
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.chrome
```
