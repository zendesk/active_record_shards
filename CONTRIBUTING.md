# Contributing

## History

All notable changes to this project will be manually documented in HISTORY.md (from v3.17.0 onwards). This file includes "Added/Removed/Changed" sections as need it.

## Changelog

All changes in code will be automatically documented in CHANGELOG.md (from v3.15.3 onwards), using [github-changelog-generator](https://github.com/github-changelog-generator/github-changelog-generator) gem to keep our changelog updated. This gem generates a changelog file based on tags, issues and merged pull requests (and splits them into separate lists according to labels) from GitHub Issue Tracker.

### Update the CHANGELOG.md using the rake task:

```sh
CHANGELOG_GITHUB_TOKEN=xxxx bundle exec rake changelog
```

**Note:** The script can make only 50 requests to GitHub API per hour without a token. To avoid this limitation please follow instructions to generate a token [here](https://github.com/github-changelog-generator/github-changelog-generator#github-token) (don't forget to enable SSO access).
