PROJECT = Praisabot.xcodeproj
SCHEME = Praisabot
SDK = iphonesimulator
CONFIG = Debug
DEVICE_NAME = iPhone 17 Pro
DERIVED_DATA = .build
BUNDLE_ID = org.savoba.Praisabot

DEVICE_ID = $(shell xcrun simctl list devices available | grep '$(DEVICE_NAME)' | head -1 | sed 's/.*(\([A-F0-9-]*\)).*/\1/')
APP_PATH = $(DERIVED_DATA)/Build/Products/$(CONFIG)-iphonesimulator/$(SCHEME).app
DEVICE_APP_PATH = $(DERIVED_DATA)/Build/Products/$(CONFIG)-iphoneos/$(SCHEME).app
PHYSICAL_DEVICE = Karl

.PHONY: generate build boot install launch run deploy clean

generate:
	cp CHANGELOG.md Praisabot/Resources/CHANGELOG.md
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

deploy: generate
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIG) \
		-derivedDataPath $(DERIVED_DATA) \
		-destination 'platform=iOS,name=$(PHYSICAL_DEVICE)' \
		build
	xcrun devicectl device install app --device $(shell xcrun devicectl list devices 2>/dev/null | grep '$(PHYSICAL_DEVICE)' | awk '{print $$3}') '$(DEVICE_APP_PATH)'

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -sdk $(SDK) clean
	rm -rf $(DERIVED_DATA)
