## 2021-03-09 - 1.0.4
  - Fixed bug where attributes were not added to nodes if it already existed in the target but had no existing attributes (Thanks rpolley)

## 2020-02-14 - 1.0.3
  - Added items to satisfy puppet-lint and pdk (Thanks silug)
  - Added better validation for verifying proper parameters passed (Thanks alexjfisher)
  - Changed syntax on attributes used by module to satisfy REXML (Thanks MacGregor001)
  - Fixed issue with Purge that caused file to be modified during each puppet run even if there were no changes (Thanks alexjfisher)
  - Added additional checks to prevent "undefined method" errors (Thanks alexjfisher)

## 2016-06-15 - 1.0.2
  - Updated the metadata to include the "dependencies" field. Some versions of Puppet can not sync plugins without this field being present.

## 2016-06-02 - 1.0.1
  - Updated requirements and dependencies to more accurately reflect the module.
  - Fixed issues in meta data where license and tags were poor.

## 2016-06-01 - Initial Release 1.0.0
