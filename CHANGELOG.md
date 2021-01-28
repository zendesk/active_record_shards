# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) (from 3.17.0 onwards)

## [Unreleased](https://github.com/zendesk/active_record_shards/tree/HEAD)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.17.0...HEAD)

**Closed issues:**

- Inconsistent readonly object [\#241](https://github.com/zendesk/active_record_shards/issues/241)
- Change the about text to say 'replicas' instead of 'slaves. [\#240](https://github.com/zendesk/active_record_shards/issues/240)

**Merged pull requests:**

- Make switch\_connection backwards compatible [\#239](https://github.com/zendesk/active_record_shards/pull/239) ([bquorning](https://github.com/bquorning))
- Switch CODEOWNERS to @zendesk/database-gem-owners [\#238](https://github.com/zendesk/active_record_shards/pull/238) ([bquorning](https://github.com/bquorning))
- Replacing master with primary [\#237](https://github.com/zendesk/active_record_shards/pull/237) ([nenox8885](https://github.com/nenox8885))
- Replace references to `slave` with `replica` and add deprecation messaging [\#216](https://github.com/zendesk/active_record_shards/pull/216) ([craig-day](https://github.com/craig-day))

## [v3.17.0](https://github.com/zendesk/active_record_shards/tree/v3.17.0) (2020-04-02)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.16.0...v3.17.0)

**Merged pull requests:**

- v3.17.0 [\#235](https://github.com/zendesk/active_record_shards/pull/235) ([bquorning](https://github.com/bquorning))
- Update circleci to run rake commands through 'bundle exec' [\#234](https://github.com/zendesk/active_record_shards/pull/234) ([zdennis](https://github.com/zdennis))
- Add \#on\_primary\_db which executes a block in the context of the prima… [\#233](https://github.com/zendesk/active_record_shards/pull/233) ([zdennis](https://github.com/zdennis))
- Upgrade RuboCop [\#230](https://github.com/zendesk/active_record_shards/pull/230) ([bquorning](https://github.com/bquorning))

## [v3.16.0](https://github.com/zendesk/active_record_shards/tree/v3.16.0) (2019-12-10)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.15.3...v3.16.0)

**Merged pull requests:**

- Bump version [\#231](https://github.com/zendesk/active_record_shards/pull/231) ([bquorning](https://github.com/bquorning))
- Test against Rails 6.0 [\#229](https://github.com/zendesk/active_record_shards/pull/229) ([zhuravel](https://github.com/zhuravel))
- Minor changes [\#228](https://github.com/zendesk/active_record_shards/pull/228) ([bquorning](https://github.com/bquorning))
- Remove all deprecated must\_\* test matchers [\#227](https://github.com/zendesk/active_record_shards/pull/227) ([bquorning](https://github.com/bquorning))
- Rails 6.0 compatibility [\#225](https://github.com/zendesk/active_record_shards/pull/225) ([zhuravel](https://github.com/zhuravel))

## [v3.15.3](https://github.com/zendesk/active_record_shards/tree/v3.15.3) (2019-11-05)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.15.2...v3.15.3)

**Merged pull requests:**

- Bump to v3.15.3 [\#224](https://github.com/zendesk/active_record_shards/pull/224) ([bquorning](https://github.com/bquorning))
- Silence the term checker [\#223](https://github.com/zendesk/active_record_shards/pull/223) ([bquorning](https://github.com/bquorning))
- Force `.where\(..\).to\_sql` to use slave connection, since it's only for escaping [\#222](https://github.com/zendesk/active_record_shards/pull/222) ([gabetax](https://github.com/gabetax))
- Use explicit block argument [\#221](https://github.com/zendesk/active_record_shards/pull/221) ([gabetax](https://github.com/gabetax))

## [v3.15.2](https://github.com/zendesk/active_record_shards/tree/v3.15.2) (2019-10-11)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.15.1...v3.15.2)

**Merged pull requests:**

- Bump to v3.15.2 [\#220](https://github.com/zendesk/active_record_shards/pull/220) ([bquorning](https://github.com/bquorning))
- TP-163 Rails 4 `where` and `having` statements should use the slave by default [\#219](https://github.com/zendesk/active_record_shards/pull/219) ([gabetax](https://github.com/gabetax))

## [v3.15.1](https://github.com/zendesk/active_record_shards/tree/v3.15.1) (2019-10-10)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.15.0...v3.15.1)

**Merged pull requests:**

- requiring sql\_comments should not connect to master [\#218](https://github.com/zendesk/active_record_shards/pull/218) ([gabetax](https://github.com/gabetax))

## [v3.15.0](https://github.com/zendesk/active_record_shards/tree/v3.15.0) (2019-06-21)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.14.0...v3.15.0)

**Merged pull requests:**

- Drop support for old Rails versions \< 4.2 [\#197](https://github.com/zendesk/active_record_shards/pull/197) ([bquorning](https://github.com/bquorning))

## [v3.14.0](https://github.com/zendesk/active_record_shards/tree/v3.14.0) (2019-03-13)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.13.1...v3.14.0)

**Merged pull requests:**

- \[HODAG-242\] Move reloading models to replica [\#215](https://github.com/zendesk/active_record_shards/pull/215) ([brianburnszd](https://github.com/brianburnszd))

## [v3.13.1](https://github.com/zendesk/active_record_shards/tree/v3.13.1) (2019-02-01)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.13.0...v3.13.1)

**Merged pull requests:**

- Revert "ActiveRecord::InternalMetadata is not sharded" [\#214](https://github.com/zendesk/active_record_shards/pull/214) ([bquorning](https://github.com/bquorning))
- Test and support Ruby \>=2.2 and \<=2.6 only [\#211](https://github.com/zendesk/active_record_shards/pull/211) ([bquorning](https://github.com/bquorning))

## [v3.13.0](https://github.com/zendesk/active_record_shards/tree/v3.13.0) (2019-01-28)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.12.0.beta2...v3.13.0)

**Closed issues:**

- Does `active\_record\_shards` support `rails 5.2.1`? [\#205](https://github.com/zendesk/active_record_shards/issues/205)

**Merged pull requests:**

- v3.13.0 [\#213](https://github.com/zendesk/active_record_shards/pull/213) ([bquorning](https://github.com/bquorning))
- Close active connections in test [\#212](https://github.com/zendesk/active_record_shards/pull/212) ([bquorning](https://github.com/bquorning))
- Debugger gem was removed 6 years ago [\#210](https://github.com/zendesk/active_record_shards/pull/210) ([bquorning](https://github.com/bquorning))
- Create Rails internal tables on all shards [\#209](https://github.com/zendesk/active_record_shards/pull/209) ([bquorning](https://github.com/bquorning))
- switch\_rails\_env needs not use Ticket [\#208](https://github.com/zendesk/active_record_shards/pull/208) ([bquorning](https://github.com/bquorning))
- Remove wwtd [\#207](https://github.com/zendesk/active_record_shards/pull/207) ([bquorning](https://github.com/bquorning))
- Use \_\_dir\_\_ [\#203](https://github.com/zendesk/active_record_shards/pull/203) ([bquorning](https://github.com/bquorning))
- Clean up test helpers [\#201](https://github.com/zendesk/active_record_shards/pull/201) ([bquorning](https://github.com/bquorning))
- Test: remove flexmaster dependency [\#200](https://github.com/zendesk/active_record_shards/pull/200) ([dadah89](https://github.com/dadah89))
- Drop Travis and use only CircleCI [\#198](https://github.com/zendesk/active_record_shards/pull/198) ([bquorning](https://github.com/bquorning))
- Tasks: correctly require adapters [\#194](https://github.com/zendesk/active_record_shards/pull/194) ([dadah89](https://github.com/dadah89))
- Require mocha 1.4.0 [\#192](https://github.com/zendesk/active_record_shards/pull/192) ([dadah89](https://github.com/dadah89))
- 3.12.0.beta2 [\#188](https://github.com/zendesk/active_record_shards/pull/188) ([bquorning](https://github.com/bquorning))
- Tuning of CI [\#187](https://github.com/zendesk/active_record_shards/pull/187) ([bquorning](https://github.com/bquorning))
- Fix abort\_if\_pending\_migration task for Rails 5.2 [\#184](https://github.com/zendesk/active_record_shards/pull/184) ([pschambacher](https://github.com/pschambacher))

## [v3.12.0.beta2](https://github.com/zendesk/active_record_shards/tree/v3.12.0.beta2) (2018-06-14)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.12.0.beta1...v3.12.0.beta2)

**Closed issues:**

- Bug: Additional connection pool is made when primary DB has no slave [\#177](https://github.com/zendesk/active_record_shards/issues/177)

**Merged pull requests:**

- Don't tell Travis to test 3-7-0 branch [\#186](https://github.com/zendesk/active_record_shards/pull/186) ([bquorning](https://github.com/bquorning))
- Reuse primary DB connection when main DB configuration has no slave [\#185](https://github.com/zendesk/active_record_shards/pull/185) ([bogdan](https://github.com/bogdan))
- Add information on current gem maintainers [\#183](https://github.com/zendesk/active_record_shards/pull/183) ([bquorning](https://github.com/bquorning))
- Circle CI [\#176](https://github.com/zendesk/active_record_shards/pull/176) ([bquorning](https://github.com/bquorning))

## [v3.12.0.beta1](https://github.com/zendesk/active_record_shards/tree/v3.12.0.beta1) (2018-06-11)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.11.5...v3.12.0.beta1)

**Merged pull requests:**

- Compatibility with Rails 5.2 [\#180](https://github.com/zendesk/active_record_shards/pull/180) ([bogdan](https://github.com/bogdan))

## [v3.11.5](https://github.com/zendesk/active_record_shards/tree/v3.11.5) (2018-05-24)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.11.4...v3.11.5)

**Merged pull requests:**

- Stop inspecting configurations, keys are enough [\#179](https://github.com/zendesk/active_record_shards/pull/179) ([bquorning](https://github.com/bquorning))

## [v3.11.4](https://github.com/zendesk/active_record_shards/tree/v3.11.4) (2018-04-18)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v4.0.0.beta9...v3.11.4)

**Merged pull requests:**

- Remove DB configuration inspection [\#178](https://github.com/zendesk/active_record_shards/pull/178) ([livathinos](https://github.com/livathinos))
- Lock down mysql2 versions [\#175](https://github.com/zendesk/active_record_shards/pull/175) ([bquorning](https://github.com/bquorning))
- add doc about migrations [\#174](https://github.com/zendesk/active_record_shards/pull/174) ([craig-day](https://github.com/craig-day))

## [v4.0.0.beta9](https://github.com/zendesk/active_record_shards/tree/v4.0.0.beta9) (2018-03-19)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.11.3...v4.0.0.beta9)

**Closed issues:**

- Is it possible to set shard\(:none\) automatically for all migrations? [\#173](https://github.com/zendesk/active_record_shards/issues/173)

**Merged pull requests:**

- Don't try to switch to unsharded db [\#171](https://github.com/zendesk/active_record_shards/pull/171) ([jacobat](https://github.com/jacobat))
- Update Rails 5.2 to use released beta [\#166](https://github.com/zendesk/active_record_shards/pull/166) ([pschambacher](https://github.com/pschambacher))

## [v3.11.3](https://github.com/zendesk/active_record_shards/tree/v3.11.3) (2017-12-27)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v4.0.0.beta8...v3.11.3)

**Merged pull requests:**

- Compatibility with Rails 5.2 [\#168](https://github.com/zendesk/active_record_shards/pull/168) ([pschambacher](https://github.com/pschambacher))
- Remove useless test [\#147](https://github.com/zendesk/active_record_shards/pull/147) ([bquorning](https://github.com/bquorning))
- Add a few warnings to the connection switcher and conf parser [\#144](https://github.com/zendesk/active_record_shards/pull/144) ([bquorning](https://github.com/bquorning))
- Ensure test files run isolated [\#141](https://github.com/zendesk/active_record_shards/pull/141) ([jacobat](https://github.com/jacobat))

## [v4.0.0.beta8](https://github.com/zendesk/active_record_shards/tree/v4.0.0.beta8) (2017-11-13)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v4.0.0.beta7...v4.0.0.beta8)

**Merged pull requests:**

- Use on\_shard? to determine shard status [\#164](https://github.com/zendesk/active_record_shards/pull/164) ([jacobat](https://github.com/jacobat))

## [v4.0.0.beta7](https://github.com/zendesk/active_record_shards/tree/v4.0.0.beta7) (2017-11-10)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v4.0.0.beta6...v4.0.0.beta7)

**Merged pull requests:**

- Remove leftovers [\#162](https://github.com/zendesk/active_record_shards/pull/162) ([bquorning](https://github.com/bquorning))
- Upgrade RuboCop, trim configuration [\#161](https://github.com/zendesk/active_record_shards/pull/161) ([bquorning](https://github.com/bquorning))
- Start testing Rails 5.2 to follow progress [\#160](https://github.com/zendesk/active_record_shards/pull/160) ([pschambacher](https://github.com/pschambacher))

## [v4.0.0.beta6](https://github.com/zendesk/active_record_shards/tree/v4.0.0.beta6) (2017-11-07)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v4.0.0.beta5...v4.0.0.beta6)

**Merged pull requests:**

- Add on\_shard? predicate [\#159](https://github.com/zendesk/active_record_shards/pull/159) ([jacobat](https://github.com/jacobat))
- Ensure boolean value returned without memoization [\#158](https://github.com/zendesk/active_record_shards/pull/158) ([jacobat](https://github.com/jacobat))

## [v4.0.0.beta5](https://github.com/zendesk/active_record_shards/tree/v4.0.0.beta5) (2017-11-07)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v4.0.0.beta4...v4.0.0.beta5)

**Merged pull requests:**

- Strict shard selection [\#157](https://github.com/zendesk/active_record_shards/pull/157) ([jacobat](https://github.com/jacobat))
- Focused switching [\#156](https://github.com/zendesk/active_record_shards/pull/156) ([jacobat](https://github.com/jacobat))
- Break up sharding and master/slave handling [\#155](https://github.com/zendesk/active_record_shards/pull/155) ([jacobat](https://github.com/jacobat))
- Fix Bundler compatibility [\#154](https://github.com/zendesk/active_record_shards/pull/154) ([bquorning](https://github.com/bquorning))
- Simplify switch block [\#153](https://github.com/zendesk/active_record_shards/pull/153) ([jacobat](https://github.com/jacobat))

## [v4.0.0.beta4](https://github.com/zendesk/active_record_shards/tree/v4.0.0.beta4) (2017-10-31)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v4.0.0.beta3...v4.0.0.beta4)

**Merged pull requests:**

- Use Kernel warn if ActiveRecord::Base.logger is undefined [\#151](https://github.com/zendesk/active_record_shards/pull/151) ([jacobat](https://github.com/jacobat))

## [v4.0.0.beta3](https://github.com/zendesk/active_record_shards/tree/v4.0.0.beta3) (2017-10-31)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v4.0.0.beta2...v4.0.0.beta3)

**Merged pull requests:**

- It's called ActiveRecord::Base.logger [\#150](https://github.com/zendesk/active_record_shards/pull/150) ([jacobat](https://github.com/jacobat))

## [v4.0.0.beta2](https://github.com/zendesk/active_record_shards/tree/v4.0.0.beta2) (2017-10-31)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v4.0.0.beta1...v4.0.0.beta2)

**Merged pull requests:**

- Soft deprecate [\#149](https://github.com/zendesk/active_record_shards/pull/149) ([jacobat](https://github.com/jacobat))

## [v4.0.0.beta1](https://github.com/zendesk/active_record_shards/tree/v4.0.0.beta1) (2017-10-26)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.11.2...v4.0.0.beta1)

**Merged pull requests:**

- Bump to 4.0.0.beta1 [\#146](https://github.com/zendesk/active_record_shards/pull/146) ([jacobat](https://github.com/jacobat))
- Remove Replica aliases [\#145](https://github.com/zendesk/active_record_shards/pull/145) ([bquorning](https://github.com/bquorning))
- Add a few warnings to the connection switcher and conf parser [\#143](https://github.com/zendesk/active_record_shards/pull/143) ([bquorning](https://github.com/bquorning))
- Test fewer rubies [\#142](https://github.com/zendesk/active_record_shards/pull/142) ([bquorning](https://github.com/bquorning))
- Ensure test files run isolated [\#140](https://github.com/zendesk/active_record_shards/pull/140) ([jacobat](https://github.com/jacobat))
- Run Travis for v4 branch [\#139](https://github.com/zendesk/active_record_shards/pull/139) ([bquorning](https://github.com/bquorning))
- Remove support for Rails 4.2 [\#138](https://github.com/zendesk/active_record_shards/pull/138) ([bquorning](https://github.com/bquorning))
- Extract migration logic [\#137](https://github.com/zendesk/active_record_shards/pull/137) ([bquorning](https://github.com/bquorning))
- Subclass switching [\#136](https://github.com/zendesk/active_record_shards/pull/136) ([jacobat](https://github.com/jacobat))
- Remove obsolete comment [\#134](https://github.com/zendesk/active_record_shards/pull/134) ([bquorning](https://github.com/bquorning))
- Upgrade RuboCop [\#133](https://github.com/zendesk/active_record_shards/pull/133) ([bquorning](https://github.com/bquorning))
- Remove unused method [\#129](https://github.com/zendesk/active_record_shards/pull/129) ([bquorning](https://github.com/bquorning))
- Remove comment for pre-Rails 3.2 code [\#128](https://github.com/zendesk/active_record_shards/pull/128) ([bquorning](https://github.com/bquorning))
- Tests: Use separate schemas for sharded and unsharded [\#127](https://github.com/zendesk/active_record_shards/pull/127) ([bquorning](https://github.com/bquorning))
- Remove Email model [\#126](https://github.com/zendesk/active_record_shards/pull/126) ([bquorning](https://github.com/bquorning))
- Remove support for Rails 3.2 [\#104](https://github.com/zendesk/active_record_shards/pull/104) ([bquorning](https://github.com/bquorning))

## [v3.11.2](https://github.com/zendesk/active_record_shards/tree/v3.11.2) (2017-09-08)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.11.1...v3.11.2)

**Merged pull requests:**

- ActiveRecord::InternalMetadata is not sharded [\#125](https://github.com/zendesk/active_record_shards/pull/125) ([bquorning](https://github.com/bquorning))
- Test released Rails 5.1 version [\#123](https://github.com/zendesk/active_record_shards/pull/123) ([bquorning](https://github.com/bquorning))

## [v3.11.1](https://github.com/zendesk/active_record_shards/tree/v3.11.1) (2017-09-06)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.11.0...v3.11.1)

**Merged pull requests:**

- patch mysql and not mysql-flexmaster [\#122](https://github.com/zendesk/active_record_shards/pull/122) ([grosser](https://github.com/grosser))
- silence [\#121](https://github.com/zendesk/active_record_shards/pull/121) ([grosser](https://github.com/grosser))
- Perform load\_schema! on slave connection [\#120](https://github.com/zendesk/active_record_shards/pull/120) ([bquorning](https://github.com/bquorning))

## [v3.11.0](https://github.com/zendesk/active_record_shards/tree/v3.11.0) (2017-09-05)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.10.0...v3.11.0)

**Merged pull requests:**

- make on\_slave\_by\_default getter and setter behave consistently [\#118](https://github.com/zendesk/active_record_shards/pull/118) ([grosser](https://github.com/grosser))
- use simpler require\_relative [\#115](https://github.com/zendesk/active_record_shards/pull/115) ([grosser](https://github.com/grosser))
- add sql comments debugging helper [\#114](https://github.com/zendesk/active_record_shards/pull/114) ([grosser](https://github.com/grosser))

## [v3.10.0](https://github.com/zendesk/active_record_shards/tree/v3.10.0) (2017-09-04)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.9.2...v3.10.0)

**Merged pull requests:**

- Upgrade RuboCop [\#119](https://github.com/zendesk/active_record_shards/pull/119) ([bquorning](https://github.com/bquorning))
- split out rubocop so we have a single failing / obvious run when addi… [\#116](https://github.com/zendesk/active_record_shards/pull/116) ([grosser](https://github.com/grosser))
- force slave for columns/table\_exist so we do not go to the master eve… [\#113](https://github.com/zendesk/active_record_shards/pull/113) ([grosser](https://github.com/grosser))
- move simple logic to the top so a raise in current\_shard\_selection do… [\#111](https://github.com/zendesk/active_record_shards/pull/111) ([grosser](https://github.com/grosser))
- simplify slave/master checking logic [\#110](https://github.com/zendesk/active_record_shards/pull/110) ([grosser](https://github.com/grosser))
- make it impossible or the reset to break [\#109](https://github.com/zendesk/active_record_shards/pull/109) ([grosser](https://github.com/grosser))
- reduce top-level files [\#108](https://github.com/zendesk/active_record_shards/pull/108) ([grosser](https://github.com/grosser))
- silence "method redefined; discarding old retrieve\_connection\_pool" [\#105](https://github.com/zendesk/active_record_shards/pull/105) ([grosser](https://github.com/grosser))

## [v3.9.2](https://github.com/zendesk/active_record_shards/tree/v3.9.2) (2017-06-16)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.9.1...v3.9.2)

**Merged pull requests:**

- Revert "`logging\_query\_plan` uses slave connection by default in Rails 3" [\#103](https://github.com/zendesk/active_record_shards/pull/103) ([pschambacher](https://github.com/pschambacher))
- Upgrade RuboCop [\#100](https://github.com/zendesk/active_record_shards/pull/100) ([bquorning](https://github.com/bquorning))
- Set/read @sharded class ivar with attr\_accessor [\#99](https://github.com/zendesk/active_record_shards/pull/99) ([bquorning](https://github.com/bquorning))

## [v3.9.1](https://github.com/zendesk/active_record_shards/tree/v3.9.1) (2017-03-29)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.9.0...v3.9.1)

**Merged pull requests:**

- Enable and fix `ruby -w` warnings [\#98](https://github.com/zendesk/active_record_shards/pull/98) ([sandlerr](https://github.com/sandlerr))

## [v3.9.0](https://github.com/zendesk/active_record_shards/tree/v3.9.0) (2017-03-21)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.8.0...v3.9.0)

**Merged pull requests:**

- schema\_migrations\_table\_name is deprecated in 5.1 [\#94](https://github.com/zendesk/active_record_shards/pull/94) ([bquorning](https://github.com/bquorning))
- Remove support for Rails 4.1 [\#93](https://github.com/zendesk/active_record_shards/pull/93) ([bquorning](https://github.com/bquorning))
- Fix for 5.1 [\#92](https://github.com/zendesk/active_record_shards/pull/92) ([bquorning](https://github.com/bquorning))
- Remove support for Rails 4.0 [\#88](https://github.com/zendesk/active_record_shards/pull/88) ([bquorning](https://github.com/bquorning))

## [v3.8.0](https://github.com/zendesk/active_record_shards/tree/v3.8.0) (2017-02-24)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.7.3...v3.8.0)

**Merged pull requests:**

- Compatibility with Rails 5.1 [\#91](https://github.com/zendesk/active_record_shards/pull/91) ([pschambacher](https://github.com/pschambacher))

## [v3.7.3](https://github.com/zendesk/active_record_shards/tree/v3.7.3) (2016-12-06)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.7.2...v3.7.3)

**Closed issues:**

- How to specify for a model to always shard to a particular database [\#87](https://github.com/zendesk/active_record_shards/issues/87)

**Merged pull requests:**

- Raise AR::AdapterNotSpecified, not RuntimeError [\#89](https://github.com/zendesk/active_record_shards/pull/89) ([bquorning](https://github.com/bquorning))
- Move DisplayCopNames to RuboCop config file [\#86](https://github.com/zendesk/active_record_shards/pull/86) ([bquorning](https://github.com/bquorning))
- silence some warnings [\#83](https://github.com/zendesk/active_record_shards/pull/83) ([grosser](https://github.com/grosser))

## [v3.7.2](https://github.com/zendesk/active_record_shards/tree/v3.7.2) (2016-09-22)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.7.1...v3.7.2)

**Merged pull requests:**

- always use a sharded connection to ask if the table exists [\#84](https://github.com/zendesk/active_record_shards/pull/84) ([osheroff](https://github.com/osheroff))
- more rubocop [\#81](https://github.com/zendesk/active_record_shards/pull/81) ([grosser](https://github.com/grosser))

## [v3.7.1](https://github.com/zendesk/active_record_shards/tree/v3.7.1) (2016-08-23)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.7.0...v3.7.1)

**Merged pull requests:**

- `logging\_query\_plan` uses slave connection by default in Rails 3 [\#82](https://github.com/zendesk/active_record_shards/pull/82) ([gabetax](https://github.com/gabetax))
- Minor fixes [\#80](https://github.com/zendesk/active_record_shards/pull/80) ([bquorning](https://github.com/bquorning))
- Add RuboCop  [\#69](https://github.com/zendesk/active_record_shards/pull/69) ([bquorning](https://github.com/bquorning))

## [v3.7.0](https://github.com/zendesk/active_record_shards/tree/v3.7.0) (2016-08-16)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.7.0.rc1...v3.7.0)

## [v3.7.0.rc1](https://github.com/zendesk/active_record_shards/tree/v3.7.0.rc1) (2016-08-01)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.6.4...v3.7.0.rc1)

**Implemented enhancements:**

- Rails 5 compatibility [\#70](https://github.com/zendesk/active_record_shards/pull/70) ([bquorning](https://github.com/bquorning))

**Merged pull requests:**

- Remove autoload\_adapter [\#79](https://github.com/zendesk/active_record_shards/pull/79) ([bquorning](https://github.com/bquorning))
- only do a short rescue for know errors, everything else shows long error [\#78](https://github.com/zendesk/active_record_shards/pull/78) ([grosser](https://github.com/grosser))
- Remove establish\_connection\_override [\#76](https://github.com/zendesk/active_record_shards/pull/76) ([bquorning](https://github.com/bquorning))
- Rubinius works not with Rails 5 [\#75](https://github.com/zendesk/active_record_shards/pull/75) ([bquorning](https://github.com/bquorning))
- Reorganize code [\#71](https://github.com/zendesk/active_record_shards/pull/71) ([bquorning](https://github.com/bquorning))
- Remove `class\_eval` and `class\<\<self` in extended [\#59](https://github.com/zendesk/active_record_shards/pull/59) ([bquorning](https://github.com/bquorning))

## [v3.6.4](https://github.com/zendesk/active_record_shards/tree/v3.6.4) (2016-05-13)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.6.3...v3.6.4)

**Merged pull requests:**

- Freeze string literals [\#67](https://github.com/zendesk/active_record_shards/pull/67) ([pschambacher](https://github.com/pschambacher))
- methods are never in public and private and always symbols ... save s… [\#66](https://github.com/zendesk/active_record_shards/pull/66) ([grosser](https://github.com/grosser))
- do not wrap methods that do not go to the master [\#65](https://github.com/zendesk/active_record_shards/pull/65) ([grosser](https://github.com/grosser))
- Start using Phenix [\#60](https://github.com/zendesk/active_record_shards/pull/60) ([pschambacher](https://github.com/pschambacher))

## [v3.6.3](https://github.com/zendesk/active_record_shards/tree/v3.6.3) (2016-03-23)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.6.2...v3.6.3)

**Merged pull requests:**

- POD-602 queries that use joins or includes+references should talk to the slav… [\#64](https://github.com/zendesk/active_record_shards/pull/64) ([grosser](https://github.com/grosser))
- cleanup / silence warnings [\#63](https://github.com/zendesk/active_record_shards/pull/63) ([grosser](https://github.com/grosser))

## [v3.6.2](https://github.com/zendesk/active_record_shards/tree/v3.6.2) (2016-02-02)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.6.1...v3.6.2)

**Merged pull requests:**

- add rails\_env back to the shard selection key [\#61](https://github.com/zendesk/active_record_shards/pull/61) ([steved](https://github.com/steved))
- A little bit of cleanup [\#58](https://github.com/zendesk/active_record_shards/pull/58) ([bquorning](https://github.com/bquorning))
- Clean up a bit [\#53](https://github.com/zendesk/active_record_shards/pull/53) ([bquorning](https://github.com/bquorning))

## [v3.6.1](https://github.com/zendesk/active_record_shards/tree/v3.6.1) (2016-01-22)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.6.0...v3.6.1)

**Merged pull requests:**

- Revert Module.prepend and replace alias\_method\_chain with alias\_method [\#57](https://github.com/zendesk/active_record_shards/pull/57) ([pschambacher](https://github.com/pschambacher))

## [v3.6.0](https://github.com/zendesk/active_record_shards/tree/v3.6.0) (2015-12-23)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.5.0...v3.6.0)

**Merged pull requests:**

- Compatibility with Rails 5.0 [\#56](https://github.com/zendesk/active_record_shards/pull/56) ([pschambacher](https://github.com/pschambacher))
- No alias\_method\_chain [\#54](https://github.com/zendesk/active_record_shards/pull/54) ([bquorning](https://github.com/bquorning))

## [v3.5.0](https://github.com/zendesk/active_record_shards/tree/v3.5.0) (2015-12-21)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.5.0.pre.alpha...v3.5.0)

**Merged pull requests:**

- Update bundle lock files [\#55](https://github.com/zendesk/active_record_shards/pull/55) ([bquorning](https://github.com/bquorning))

## [v3.5.0.pre.alpha](https://github.com/zendesk/active_record_shards/tree/v3.5.0.pre.alpha) (2015-08-06)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.4.3...v3.5.0.pre.alpha)

**Merged pull requests:**

- Instantiate fewer objects [\#51](https://github.com/zendesk/active_record_shards/pull/51) ([bquorning](https://github.com/bquorning))
- Open to Rubinius [\#49](https://github.com/zendesk/active_record_shards/pull/49) ([pschambacher](https://github.com/pschambacher))

## [v3.4.3](https://github.com/zendesk/active_record_shards/tree/v3.4.3) (2015-04-29)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.4.2...v3.4.3)

**Merged pull requests:**

- Fix charset / collation for rails 4 [\#48](https://github.com/zendesk/active_record_shards/pull/48) ([steved](https://github.com/steved))

## [v3.4.2](https://github.com/zendesk/active_record_shards/tree/v3.4.2) (2015-03-20)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.4.1...v3.4.2)

**Merged pull requests:**

- use a "root connection" for rails 3 db dropping [\#47](https://github.com/zendesk/active_record_shards/pull/47) ([steved](https://github.com/steved))
- make sure to invoke rake tasks in the same scope [\#46](https://github.com/zendesk/active_record_shards/pull/46) ([steved](https://github.com/steved))

## [v3.4.1](https://github.com/zendesk/active_record_shards/tree/v3.4.1) (2015-03-16)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.3.8...v3.4.1)

**Merged pull requests:**

- Allow disabling sharding on ActiveRecord::Base [\#44](https://github.com/zendesk/active_record_shards/pull/44) ([staugaard](https://github.com/staugaard))

## [v3.3.8](https://github.com/zendesk/active_record_shards/tree/v3.3.8) (2015-03-12)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.3.7...v3.3.8)

**Merged pull requests:**

- Fix execute of 'rake db:test:load' standalone. [\#43](https://github.com/zendesk/active_record_shards/pull/43) ([ghost](https://github.com/ghost))
- base\_class should ask AR::Base about is\_sharded? [\#42](https://github.com/zendesk/active_record_shards/pull/42) ([staugaard](https://github.com/staugaard))

## [v3.3.7](https://github.com/zendesk/active_record_shards/tree/v3.3.7) (2015-02-27)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.3.6...v3.3.7)

**Merged pull requests:**

- AR::Base is only sharded if sharding is supported [\#41](https://github.com/zendesk/active_record_shards/pull/41) ([staugaard](https://github.com/staugaard))

## [v3.3.6](https://github.com/zendesk/active_record_shards/tree/v3.3.6) (2015-02-12)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.3.5...v3.3.6)

**Merged pull requests:**

- put Rails.env into the shard key [\#40](https://github.com/zendesk/active_record_shards/pull/40) ([osheroff](https://github.com/osheroff))

## [v3.3.5](https://github.com/zendesk/active_record_shards/tree/v3.3.5) (2015-02-06)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.3.4...v3.3.5)

**Merged pull requests:**

- Fix chaining rake tasks. [\#39](https://github.com/zendesk/active_record_shards/pull/39) ([ghost](https://github.com/ghost))

## [v3.3.4](https://github.com/zendesk/active_record_shards/tree/v3.3.4) (2015-02-05)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.3.3...v3.3.4)

**Merged pull requests:**

- Shender/rails 4.2 test env db creation fix [\#38](https://github.com/zendesk/active_record_shards/pull/38) ([ghost](https://github.com/ghost))
- Shender/test purge support [\#37](https://github.com/zendesk/active_record_shards/pull/37) ([ghost](https://github.com/ghost))

## [v3.3.3](https://github.com/zendesk/active_record_shards/tree/v3.3.3) (2015-01-23)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.3.2...v3.3.3)

**Merged pull requests:**

- check if Rails.env is defined [\#36](https://github.com/zendesk/active_record_shards/pull/36) ([staugaard](https://github.com/staugaard))

## [v3.3.2](https://github.com/zendesk/active_record_shards/tree/v3.3.2) (2015-01-21)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.3.0...v3.3.2)

**Merged pull requests:**

- habtm sharded-ness fix [\#35](https://github.com/zendesk/active_record_shards/pull/35) ([osheroff](https://github.com/osheroff))
- Fix for v4.2.0 rails abort\_if\_pending\_migrations task. [\#34](https://github.com/zendesk/active_record_shards/pull/34) ([ghost](https://github.com/ghost))

## [v3.3.0](https://github.com/zendesk/active_record_shards/tree/v3.3.0) (2015-01-06)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.2.1...v3.3.0)

**Merged pull requests:**

- Compatibility with Rails 4.2 [\#29](https://github.com/zendesk/active_record_shards/pull/29) ([pschambacher](https://github.com/pschambacher))

## [v3.2.1](https://github.com/zendesk/active_record_shards/tree/v3.2.1) (2014-12-10)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.2.0...v3.2.1)

**Closed issues:**

- Thread Safe : \(RuntimeError\) Can't add a new key into hash during iteration [\#23](https://github.com/zendesk/active_record_shards/issues/23)

**Merged pull requests:**

- Fix default spec in establish\_connection on rails 4.1 [\#32](https://github.com/zendesk/active_record_shards/pull/32) ([staugaard](https://github.com/staugaard))

## [v3.2.0](https://github.com/zendesk/active_record_shards/tree/v3.2.0) (2014-11-11)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.1.0...v3.2.0)

**Merged pull requests:**

- Add Base.shards for console-convience [\#30](https://github.com/zendesk/active_record_shards/pull/30) ([osheroff](https://github.com/osheroff))
- Rails 4.1 compatibility [\#28](https://github.com/zendesk/active_record_shards/pull/28) ([bquorning](https://github.com/bquorning))
- Remove Appraisal, use WWTD [\#27](https://github.com/zendesk/active_record_shards/pull/27) ([bquorning](https://github.com/bquorning))
- specs against ruby 2.1.2 [\#26](https://github.com/zendesk/active_record_shards/pull/26) ([sandlerr](https://github.com/sandlerr))
- Ruby 1.8 support [\#25](https://github.com/zendesk/active_record_shards/pull/25) ([vkmita](https://github.com/vkmita))

## [v3.1.0](https://github.com/zendesk/active_record_shards/tree/v3.1.0) (2014-07-09)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.0.0.beta4...v3.1.0)

**Fixed bugs:**

- rake db:test:purge not working [\#22](https://github.com/zendesk/active_record_shards/issues/22)

**Closed issues:**

- rake tasks are broken on rails4 [\#20](https://github.com/zendesk/active_record_shards/issues/20)

**Merged pull requests:**

- patch rails 4 schema.rb generation to include sharded tables [\#24](https://github.com/zendesk/active_record_shards/pull/24) ([gabetax](https://github.com/gabetax))

## [v3.0.0.beta4](https://github.com/zendesk/active_record_shards/tree/v3.0.0.beta4) (2014-06-05)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.0.0.beta3...v3.0.0.beta4)

**Merged pull requests:**

- Fix rake tasks: db:create, db:drop and db:migrate [\#21](https://github.com/zendesk/active_record_shards/pull/21) ([lukkry](https://github.com/lukkry))

## [v3.0.0.beta3](https://github.com/zendesk/active_record_shards/tree/v3.0.0.beta3) (2014-04-25)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.0.0.beta2...v3.0.0.beta3)

**Closed issues:**

- rake task broken [\#18](https://github.com/zendesk/active_record_shards/issues/18)

**Merged pull requests:**

- clean is actually clear [\#19](https://github.com/zendesk/active_record_shards/pull/19) ([staugaard](https://github.com/staugaard))
- Remove deprecations for AR4 tests [\#15](https://github.com/zendesk/active_record_shards/pull/15) ([jacobat](https://github.com/jacobat))
- More Rails 4 support [\#14](https://github.com/zendesk/active_record_shards/pull/14) ([bquorning](https://github.com/bquorning))

## [v3.0.0.beta2](https://github.com/zendesk/active_record_shards/tree/v3.0.0.beta2) (2014-01-31)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v3.0.0.beta...v3.0.0.beta2)

## [v3.0.0.beta](https://github.com/zendesk/active_record_shards/tree/v3.0.0.beta) (2014-01-31)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.8.0...v3.0.0.beta)

**Merged pull requests:**

- simplify task hacks [\#13](https://github.com/zendesk/active_record_shards/pull/13) ([grosser](https://github.com/grosser))
- Rails 4 [\#12](https://github.com/zendesk/active_record_shards/pull/12) ([lukkry](https://github.com/lukkry))
- cleanup gemspec [\#11](https://github.com/zendesk/active_record_shards/pull/11) ([grosser](https://github.com/grosser))
- drop support for everything pre 3.2 Edit [\#10](https://github.com/zendesk/active_record_shards/pull/10) ([grosser](https://github.com/grosser))
- Removed some comments in the tests [\#9](https://github.com/zendesk/active_record_shards/pull/9) ([jeffreytheobald](https://github.com/jeffreytheobald))

## [v2.8.0](https://github.com/zendesk/active_record_shards/tree/v2.8.0) (2013-11-22)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.7.4...v2.8.0)

**Merged pull requests:**

- Support has\_and\_belongs\_to\_many :include on slave by default [\#8](https://github.com/zendesk/active_record_shards/pull/8) ([osheroff](https://github.com/osheroff))
- Support .pluck on slave by default [\#7](https://github.com/zendesk/active_record_shards/pull/7) ([osheroff](https://github.com/osheroff))
- Patch ActiveRecord 3 `exists?` with scopes [\#4](https://github.com/zendesk/active_record_shards/pull/4) ([seancaffery](https://github.com/seancaffery))

## [v2.7.4](https://github.com/zendesk/active_record_shards/tree/v2.7.4) (2013-07-16)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.7.3...v2.7.4)

**Merged pull requests:**

- introduce shard\_status on migrator [\#3](https://github.com/zendesk/active_record_shards/pull/3) ([grosser](https://github.com/grosser))
- make travis build more granular [\#2](https://github.com/zendesk/active_record_shards/pull/2) ([grosser](https://github.com/grosser))
- simplify after\_initialize callbacks [\#1](https://github.com/zendesk/active_record_shards/pull/1) ([grosser](https://github.com/grosser))

## [v2.7.3](https://github.com/zendesk/active_record_shards/tree/v2.7.3) (2013-06-06)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.7.2...v2.7.3)

## [v2.7.2](https://github.com/zendesk/active_record_shards/tree/v2.7.2) (2013-03-14)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.7.1...v2.7.2)

## [v2.7.1](https://github.com/zendesk/active_record_shards/tree/v2.7.1) (2013-03-13)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.7.0...v2.7.1)

## [v2.7.0](https://github.com/zendesk/active_record_shards/tree/v2.7.0) (2013-02-07)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.6.7...v2.7.0)

## [v2.6.7](https://github.com/zendesk/active_record_shards/tree/v2.6.7) (2013-01-16)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.6.6...v2.6.7)

## [v2.6.6](https://github.com/zendesk/active_record_shards/tree/v2.6.6) (2013-01-15)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.6.5...v2.6.6)

## [v2.6.5](https://github.com/zendesk/active_record_shards/tree/v2.6.5) (2012-06-18)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.6.4...v2.6.5)

## [v2.6.4](https://github.com/zendesk/active_record_shards/tree/v2.6.4) (2012-06-07)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.6.3...v2.6.4)

## [v2.6.3](https://github.com/zendesk/active_record_shards/tree/v2.6.3) (2012-05-10)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.6.2...v2.6.3)

## [v2.6.2](https://github.com/zendesk/active_record_shards/tree/v2.6.2) (2012-03-09)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.6.1...v2.6.2)

## [v2.6.1](https://github.com/zendesk/active_record_shards/tree/v2.6.1) (2012-03-09)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.6.0...v2.6.1)

## [v2.6.0](https://github.com/zendesk/active_record_shards/tree/v2.6.0) (2012-03-07)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.5.10...v2.6.0)

## [v2.5.10](https://github.com/zendesk/active_record_shards/tree/v2.5.10) (2012-02-08)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.5.9...v2.5.10)

## [v2.5.9](https://github.com/zendesk/active_record_shards/tree/v2.5.9) (2012-02-07)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.5.8...v2.5.9)

## [v2.5.8](https://github.com/zendesk/active_record_shards/tree/v2.5.8) (2012-01-31)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.5.7...v2.5.8)

## [v2.5.7](https://github.com/zendesk/active_record_shards/tree/v2.5.7) (2012-01-26)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.5.4...v2.5.7)

## [v2.5.4](https://github.com/zendesk/active_record_shards/tree/v2.5.4) (2012-01-18)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.5.3...v2.5.4)

## [v2.5.3](https://github.com/zendesk/active_record_shards/tree/v2.5.3) (2012-01-03)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.5.2...v2.5.3)

## [v2.5.2](https://github.com/zendesk/active_record_shards/tree/v2.5.2) (2011-11-01)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.5.1...v2.5.2)

## [v2.5.1](https://github.com/zendesk/active_record_shards/tree/v2.5.1) (2011-11-01)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.5.0...v2.5.1)

## [v2.5.0](https://github.com/zendesk/active_record_shards/tree/v2.5.0) (2011-10-28)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.4.2...v2.5.0)

## [v2.4.2](https://github.com/zendesk/active_record_shards/tree/v2.4.2) (2011-08-31)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.4.1...v2.4.2)

## [v2.4.1](https://github.com/zendesk/active_record_shards/tree/v2.4.1) (2011-08-31)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.3.1...v2.4.1)

## [v2.3.1](https://github.com/zendesk/active_record_shards/tree/v2.3.1) (2011-06-13)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.3.0...v2.3.1)

## [v2.3.0](https://github.com/zendesk/active_record_shards/tree/v2.3.0) (2011-05-23)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.2.0...v2.3.0)

## [v2.2.0](https://github.com/zendesk/active_record_shards/tree/v2.2.0) (2011-05-05)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.1.0...v2.2.0)

## [v2.1.0](https://github.com/zendesk/active_record_shards/tree/v2.1.0) (2011-04-26)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.0.0...v2.1.0)

## [v2.0.0](https://github.com/zendesk/active_record_shards/tree/v2.0.0) (2011-03-11)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.0.0.beta5...v2.0.0)

## [v2.0.0.beta5](https://github.com/zendesk/active_record_shards/tree/v2.0.0.beta5) (2011-02-11)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.0.0.beta4...v2.0.0.beta5)

## [v2.0.0.beta4](https://github.com/zendesk/active_record_shards/tree/v2.0.0.beta4) (2011-02-04)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.0.0.beta3...v2.0.0.beta4)

## [v2.0.0.beta3](https://github.com/zendesk/active_record_shards/tree/v2.0.0.beta3) (2011-02-04)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.0.0.beta2...v2.0.0.beta3)

## [v2.0.0.beta2](https://github.com/zendesk/active_record_shards/tree/v2.0.0.beta2) (2011-01-20)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v2.0.0.beta1...v2.0.0.beta2)

## [v2.0.0.beta1](https://github.com/zendesk/active_record_shards/tree/v2.0.0.beta1) (2011-01-20)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/v1.2.0...v2.0.0.beta1)

## [v1.2.0](https://github.com/zendesk/active_record_shards/tree/v1.2.0) (2010-02-09)

[Full Changelog](https://github.com/zendesk/active_record_shards/compare/4a4f60c5c672bcbda9fb1b7ca956030150af506c...v1.2.0)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
