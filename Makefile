PROJECT = Praisabot.xcodeproj
SCHEME = Praisabot
SDK = iphonesimulator
CONFIG = Debug
DEVICE_NAME = iPhone 17 Pro
DERIVED_DATA = .build
BUNDLE_ID = org.savoba.Praisabot

DEVICE_ID = $(shell xcrun simctl list devices available | grep '$(DEVICE_NAME)' | head -1 | sed 's/.*(\([A-F0-9-]*\)).*/\1/')
APP_PATH = $(DERIVED_DATA)/Build/Products/$(CONFIG)-iphonesimulator/$(SCHEME).app

.PHONY: generate build boot install launch run clean

generate:
	xcodegen generate

build: generate
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-sdk $(SDK) \
		-configuration $(CONFIG) \
		-derivedDataPath $(DERIVED_DATA) \
		-destination 'platform=iOS Simulator,name=$(DEVICE_NAME)' \
		build

boot:
	xcrun simctl boot '$(DEVICE_ID)' 2>/dev/null || true
	open -a Simulator

install: build boot
	xcrun simctl install '$(DEVICE_ID)' '$(APP_PATH)'

launch:
	xcrun simctl launch '$(DEVICE_ID)' $(BUNDLE_ID)

run: install launch

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -sdk $(SDK) clean
	rm -rf $(DERIVED_DATA)
