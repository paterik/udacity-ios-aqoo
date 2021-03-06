# ChangeLog of AQOO

All notable changes of AQOO release series are documented in this file using the [Keep a CHANGELOG](http://keepachangelog.com/) principles.

_This AQOO project changelog documentation start with version 0.0.1 (2017-07-18)_

## [1.0.5], 2018-12-15:
_current_

### Added

* travis ci build status including a working travis-ci build/test pipeline

### Fixed

* bug in cell-based playlist hide process
* bug in network indicator view state during long playlist load process
* bug in playMode reset on app crash (playMode was still activ on old playlist)
* structural and logical improvements/fixes after 3rd review
* minor documentation/changelog issues


## [1.0.4], 2018-12-14:

### Added

* unit tests for DateHelper (DFDates) class
* unit tests for NumberHelper (DFNumbers) class

### Fixed

* bug in manual playlist refresh action that prevent track meta data loading
* bug in DateHelper class, error in mm:ss formatter on seconds > 60
* bug in DateHelper class, error in getDateAsString function on user defined dates
* image caching problem in playlist cover sets
* image quality problem on playlistCover rendering
* structural and logical improvements/fixes after 2nd review
* minor constraint issues in playlist colletion view
* minor documentation/changelog issues
* minor changes in travis build processor

### Removed

* playlist identification icon rendering in playlist collection view
* old code (action) fragments related to extended play-controls in playlist table view


## [1.0.3], 2018-12-12:

### Added

* travis ci build processor for XCode 10.1 (Swift 4.2.1)
* extended documentation for XCode 9 and XCode 10 usage
* extended documentation for "known issues"
* new tracklist based spotify playlist cover image processor
* new  progress indicator during spotify request auth process
* new connection check handler for all net related view controls

### Fixed

* pod vendor library stack (some upgrades, some downgrades)
* spotify playlist cover image processor (after major API changes)
* structural and logical code changes after first review
* problems in view constraints of some views

## [1.0.2], 2018-12-10:

### Fixed

* downgrade Pod/MaterialComponents (to 70.0.0)
* fix dependency branch problems in Podfile definitions


## [1.0.1], 2018-12-09:

### Added

* support for new xcode 10.1 (10B61)
* support for new swift 4.2.1 (2018-10-30(a))

### Fixed

* compile/link errors on new swift 4.2 and xcode 10.1 release


## [1.0.0], 2018-12-09:

### Added

* playlist cell detail meta drawout
* playlist cell playback function
* playlist cell control functionality
* playlist cover view
* playlist filter functionality
* playlist edit functionality
* tracklist view / playlist meta cell
* tracklist playback functions
* tracklist playback (sub) controls

### Fixed

* major issue with async process controls
* data model reference mismatch issue between track and playlist
* data model relationial issue for playlist tags
* minor bugs and structural issues
* spelling issues in documentation

### Removed

* multi streaming provider functionality
* spotify origin source app authentication


## [0.9.9], 2018-07-08:

### Added

* playlist view
* playlist editView(s)
* playlist cell/coverView
* trackView / trackPlaylistCell
* trackView playMode controls

## [0.9.8], 2017-12-31:

### Added

* main code base (SDK integration)
* minor documentation
* changelog and license

## [0.0.1], 2017-07-18:

### Added

* initial commit