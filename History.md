# Asset Cloud Version History

## Version 2.7.2, 2023-04-20

* Swap the order of operations for checking UUID and asset exist logic in free key locator (https://github.com/Shopify/asset_cloud/pull/83)

## Version 2.7.1, 2022-03-18

* Fix incorrect invocation of callbacks defined in external classes (https://github.com/Shopify/asset_cloud/issues/71)

## Version 2.7.0, 2020-07-15

* Add `Asset#write!` which raises on validation failure (https://github.com/Shopify/asset_cloud/pull/67)

## Version 2.6.0, 2020-05-22

* Add checksum to metadata (https://github.com/Shopify/asset_cloud/pull/57)

**Note:** There are versions between 2.2.2 and 2.6.0 not covered by the History.

## Version 2.2.2, 2016-02-11

* Allow asset_class to be a proc which determines the class to use within a bucket (https://github.com/Shopify/asset_cloud/pull/15)

## Version 2.2.0, 2015-03-17

* Reduce the limitations on filenames so as not to catch valid filenames. (https://github.com/Shopify/asset_cloud/pull/12)

## Version 2.1.0, 2015-03-03

* Add support for S3 assests https://github.com/Shopify/asset_cloud/pull/7

## Version 2.0.0, 2014-09-26

* Change the way methods on asset extensions are invoke so it won't silently swallow exceptions [#3](https://github.com/Shopify/asset_cloud/pull/3).
