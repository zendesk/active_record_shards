### Committing a change

#### Development

When opening a pull request, add your changes to the "[Unreleased]" section of the [changelog](https://github.com/zendesk/active_record_shards/blob/master/Changelog.md).

#### Release

After merging your changes into master, cut a tag and push it immediately:

1.  Create a new branch for the version bump
2.  Update the version in active_record_shards.gemspec
2.  Insert the version as a new header in the [changelog](https://github.com/zendesk/active_record_shards/blob/master/Changelog.md)
    (right under the "[Unreleased]" section).
3.  Check in the changes `git add Changelog.md; git commit --amend --no-edit;`
4.  Create a Pull Request
