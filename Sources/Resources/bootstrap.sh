#!/bin/bash
#
#  bootstrap.sh
#
#  Configures an Xcode project for use with AppSubsystem.
#
#  This script scaffolds the source files, build settings, build
#  phases, package dependencies, and scheme environment variables
#  required to adopt AppSubsystem in an existing Xcode project.
#
#  Usage:
#
#      bootstrap.sh [--target <path>]
#
#  Options:
#
#      --target <path>     Path to the .xcodeproj bundle. When omitted,
#                          the script searches the current working
#                          directory for a .xcodeproj and infers the
#                          target name from its filename.
#
#  Created files:
#
#      <target>/AppDelegate.swift
#      <target>/ContentView.swift
#      <target>/SceneDelegate.swift
#      <target>/Info.plist
#      <target>/LocalizedStrings.plist
#
#  Copyright (c) NEOTechnica Corporation. All rights reserved.
#

set -euo pipefail


# ===================================================================
# MARK: - Terminal Formatting
# ===================================================================

SUPPORTS_COLOR=false
if [[ -t 1 ]] && [[ "$(tput colors 2>/dev/null)" -ge 8 ]]; then
    SUPPORTS_COLOR=true
fi

format_bold=""
format_dim=""
format_reset=""
format_green=""
format_yellow=""
format_red=""
format_cyan=""

if [[ "$SUPPORTS_COLOR" == true ]]; then
    format_bold=$(tput bold)
    format_dim=$(tput dim)
    format_reset=$(tput sgr0)
    format_green=$(tput setaf 2)
    format_yellow=$(tput setaf 3)
    format_red=$(tput setaf 1)
    format_cyan=$(tput setaf 6)
fi


# ===================================================================
# MARK: - Logging
# ===================================================================

log_created() {
    local description="$1"
    printf "  ${format_green}✓${format_reset}  Created   %s\n" "$description"
}

log_updated() {
    local description="$1"
    printf "  ${format_green}✓${format_reset}  Updated   %s\n" "$description"
}

log_skipped() {
    local description="$1"
    printf "  ${format_dim}–  Skipped   %s${format_reset}\n" "$description"
}

log_removed() {
    local description="$1"
    printf "  ${format_cyan}✓${format_reset}  Removed   %s\n" "$description"
}

log_warning() {
    local description="$1"
    printf "  ${format_yellow}!${format_reset}  Warning   %s\n" "$description"
}

log_error() {
    local description="$1"
    printf "  ${format_red}✗${format_reset}  Error     %s\n" "$description" >&2
}

log_detail() {
    local description="$1"
    printf "              %s\n" "$description"
}


# ===================================================================
# MARK: - Parse Arguments
# ===================================================================

target_path=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            target_path="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: bootstrap.sh [--target <path>]"
            echo ""
            echo "Options:"
            echo "  --target <path>   Path to the .xcodeproj bundle."
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "  Run with --help for usage information."
            exit 1
            ;;
    esac
done


# ===================================================================
# MARK: - Resolve Target
# ===================================================================

if [[ -n "$target_path" ]]; then
    if [[ "$target_path" != *.xcodeproj ]]; then
        log_error "Expected a path ending in .xcodeproj: $target_path"
        exit 1
    fi

    if [[ ! -d "$target_path" ]]; then
        log_error "Xcode project does not exist: $target_path"
        exit 1
    fi

    target_name=$(basename "$target_path" .xcodeproj)
    cd "$(dirname "$target_path")"
else
    xcode_project_bundle=$(find . -maxdepth 1 -name "*.xcodeproj" -print -quit)

    if [[ -z "$xcode_project_bundle" ]]; then
        log_error "No .xcodeproj found in $(pwd)."
        echo "  Pass --target <path> or run this script from the project root."
        exit 1
    fi

    target_name=$(basename "$xcode_project_bundle" .xcodeproj)
fi

target_source_directory="$target_name"

if [[ ! -d "$target_source_directory" ]]; then
    mkdir -p "$target_source_directory"
fi


# ===================================================================
# MARK: - Banner
# ===================================================================

echo ""
echo "${format_bold}  AppSubsystem Bootstrap${format_reset}"
echo "${format_dim}  Configuring ${target_name}...${format_reset}"
echo ""


# ===================================================================
# MARK: - Remove Existing @main Entry Point
# ===================================================================
#
# Xcode's default SwiftUI template generates a file annotated with
# @main. Because AppSubsystem uses a UIKit-based AppDelegate as the
# application entry point, the template's @main struct must be removed
# to avoid a duplicate entry point error at compile time.

existing_main_file=$(grep -rlm 1 '@main' "$target_source_directory"/*.swift 2>/dev/null || true)

if [[ -n "$existing_main_file" ]]; then
    rm "$existing_main_file"
    log_removed "$existing_main_file (conflicting @main entry point)"
fi


# ===================================================================
# MARK: - Scaffold Source Files
# ===================================================================

# -- AppDelegate.swift ----------------------------------------------

app_delegate_path="$target_source_directory/AppDelegate.swift"

if [[ -f "$app_delegate_path" ]]; then
    log_skipped "$app_delegate_path (already exists)"
else
    cat > "$app_delegate_path" << 'SWIFT'
//
//  AppDelegate.swift
//

import AppSubsystem
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AppSubsystem.initialize(
            appStoreBuildNumber: 0,
            buildMilestone: .preAlpha,
            codeName: "Alpine",
            finalName: "My App",
            languageCode: Locale.systemLanguageCode,
            loggingEnabled: true
        )

        return true
    }
}
SWIFT
    log_created "$app_delegate_path"
fi

# -- SceneDelegate.swift --------------------------------------------

scene_delegate_path="$target_source_directory/SceneDelegate.swift"

if [[ -f "$scene_delegate_path" ]]; then
    log_skipped "$scene_delegate_path (already exists)"
else
    cat > "$scene_delegate_path" << 'SWIFT'
//
//  SceneDelegate.swift
//

import AppSubsystem
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // MARK: - Properties

    var window: UIWindow?

    // MARK: - UIScene

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        window = RootWindowScene.instantiate(
            scene,
            rootView: ContentView() // Replace with your root view.
        )
    }

    // MARK: - UIWindowScene

    func windowScene(
        _ windowScene: UIWindowScene,
        didUpdate previousCoordinateSpace: UICoordinateSpace,
        interfaceOrientation previousInterfaceOrientation:
        UIInterfaceOrientation,
        traitCollection previousTraitCollection: UITraitCollection
    ) {
        RootWindowScene.traitCollectionChanged()
    }
}
SWIFT
    log_created "$scene_delegate_path"
fi

# -- Info.plist -----------------------------------------------------

info_plist_path="$target_source_directory/Info.plist"

if [[ -f "$info_plist_path" ]]; then
    log_skipped "$info_plist_path (already exists)"
else
    cat > "$info_plist_path" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBuildDate</key>
    <string>1183100400</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.0.0</string>
    <key>CFBundleVersion</key>
    <string>0</string>
    <key>CFFirstCompileDate</key>
    <string>1183100400</string>
    <key>CFTargetName</key>
    <string>$(TARGET_NAME)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Photo library access is requested to save images for Breadcrumbs capture.</string>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
        <key>UISceneConfigurations</key>
        <dict>
            <key>UIWindowSceneSessionRoleApplication</key>
            <array>
                <dict>
                    <key>UISceneConfigurationName</key>
                    <string>Default Configuration</string>
                    <key>UISceneDelegateClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                </dict>
            </array>
        </dict>
    </dict>
    <key>UIDesignRequiresCompatibility</key>
    <false/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
    </array>
</dict>
</plist>
PLIST
    log_created "$info_plist_path"
fi

# -- ContentView.swift ----------------------------------------------

content_view_path="$target_source_directory/ContentView.swift"

if [[ -f "$content_view_path" ]]; then
    log_skipped "$content_view_path (already exists)"
else
    cat > "$content_view_path" << 'SWIFT'
//
//  ContentView.swift
//

import AppSubsystem
import ComponentKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        Components.text("Hello, world!")
    }
}
SWIFT
    log_created "$content_view_path"
fi

# -- LocalizedStrings.plist -----------------------------------------
#
# The app's localized strings property list is separate from the
# framework's own. Generate a starter file with a single key so
# that adopting apps have a working example out of the box.

localized_strings_path="$target_source_directory/LocalizedStrings.plist"

if [[ -f "$localized_strings_path" ]]; then
    log_skipped "$localized_strings_path (already exists)"
else
    cat > "$localized_strings_path" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>hello_world</key>
    <dict>
        <key>af</key>
        <string>Hallo, wêreld!</string>
        <key>ar</key>
        <string>مرحبا بالعالم!</string>
        <key>az</key>
        <string>Salam, dünya!</string>
        <key>be</key>
        <string>Прывітанне, свет!</string>
        <key>bg</key>
        <string>Здравей, свят!</string>
        <key>bn</key>
        <string>হ্যালো, বিশ্ব!</string>
        <key>bs</key>
        <string>Zdravo, svijete!</string>
        <key>ca</key>
        <string>Hola, món!</string>
        <key>cs</key>
        <string>Ahoj, světe!</string>
        <key>cy</key>
        <string>Helô, byd!</string>
        <key>da</key>
        <string>Hej, verden!</string>
        <key>de</key>
        <string>Hallo, Welt!</string>
        <key>el</key>
        <string>Γεια σου, κόσμε!</string>
        <key>en</key>
        <string>Hello, world!</string>
        <key>eo</key>
        <string>Saluton, mondo!</string>
        <key>es</key>
        <string>¡Hola, mundo!</string>
        <key>et</key>
        <string>Tere, maailm!</string>
        <key>eu</key>
        <string>Kaixo, mundua!</string>
        <key>fa</key>
        <string>سلام، دنیا!</string>
        <key>fi</key>
        <string>Hei, maailma!</string>
        <key>fr</key>
        <string>Bonjour le monde!</string>
        <key>ga</key>
        <string>Dia duit, domhan!</string>
        <key>gd</key>
        <string>Halò, a shaoghail!</string>
        <key>gl</key>
        <string>Ola, mundo!</string>
        <key>gu</key>
        <string>હેલો દુનિયા!</string>
        <key>he</key>
        <string>שלום, עולם!</string>
        <key>hi</key>
        <string>हैलो वर्ल्ड!</string>
        <key>hr</key>
        <string>Pozdrav, svijete!</string>
        <key>ht</key>
        <string>Bonjou, lemonn!</string>
        <key>hu</key>
        <string>Helló, világ!</string>
        <key>hy</key>
        <string>Բարև, աշխարհ։</string>
        <key>id</key>
        <string>Halo, dunia!</string>
        <key>is</key>
        <string>Halló, heimur!</string>
        <key>it</key>
        <string>Ciao, mondo!</string>
        <key>ja</key>
        <string>こんにちは世界！</string>
        <key>ka</key>
        <string>Გამარჯობა, სამყარო!</string>
        <key>kk</key>
        <string>Сәлем, әлем!</string>
        <key>kn</key>
        <string>ನಮಸ್ಕಾರ ಜಗತ್ತೇ!</string>
        <key>ko</key>
        <string>안녕하세요, 세상아!</string>
        <key>ky</key>
        <string>Салам дүйнө!</string>
        <key>lt</key>
        <string>Sveikas, pasauli!</string>
        <key>mg</key>
        <string>Salama, tontolo!</string>
        <key>mi</key>
        <string>Kia ora, te ao!</string>
        <key>mk</key>
        <string>Здраво, свету!</string>
        <key>ml</key>
        <string>ഹലോ വേൾഡ്!</string>
        <key>mn</key>
        <string>Сайн уу, дэлхий!</string>
        <key>mt</key>
        <string>Bongu, dinja!</string>
        <key>ne</key>
        <string>नमस्ते, संसार!</string>
        <key>nl</key>
        <string>Hallo, wereld!</string>
        <key>no</key>
        <string>Hei, verden!</string>
        <key>pa</key>
        <string>ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ ਦੁਨਿਆ!</string>
        <key>pl</key>
        <string>Witaj, świecie!</string>
        <key>pt</key>
        <string>Olá, mundo!</string>
        <key>ro</key>
        <string>Salut, lume!</string>
        <key>ru</key>
        <string>Привет, мир!</string>
        <key>si</key>
        <string>හෙලෝ වර්ල්ඩ්!</string>
        <key>sk</key>
        <string>Ahoj, svet!</string>
        <key>sl</key>
        <string>Pozdravljen, svet!</string>
        <key>sq</key>
        <string>Përshëndetje, botë!</string>
        <key>sr</key>
        <string>Здраво, свете!</string>
        <key>su</key>
        <string>Halo, dunya!</string>
        <key>sv</key>
        <string>Hej världen!</string>
        <key>sw</key>
        <string>Habari, dunia!</string>
        <key>ta</key>
        <string>வணக்கம், உலகம்!</string>
        <key>te</key>
        <string>నమస్కారం, ప్రపంచమా!</string>
        <key>tg</key>
        <string>Салом Ҷаҳон!</string>
        <key>th</key>
        <string>สวัสดีชาวโลก!</string>
        <key>tl</key>
        <string>Kumusta, mundo!</string>
        <key>tr</key>
        <string>Selam, dünya!</string>
        <key>tt</key>
        <string>Сәлам, дөнья!</string>
        <key>uk</key>
        <string>Привіт, світе!</string>
        <key>ur</key>
        <string>ہیلو، دنیا!</string>
        <key>uz</key>
        <string>Salom, dunyo!</string>
        <key>vi</key>
        <string>Xin chào thế giới!</string>
        <key>yi</key>
        <string>העלא, וועלט!</string>
        <key>zh</key>
        <string>你好世界！</string>
    </dict>
</dict>
</plist>
PLIST
    log_created "$localized_strings_path"
fi

echo ""


# ===================================================================
# MARK: - Configure project.pbxproj
# ===================================================================
#
# All project file modifications are handled by a single inline
# Python script so the file is read and written atomically. Python 3
# ships with Xcode Command Line Tools on macOS.
#
# The script performs four operations:
#
#   1. Adjust build settings (sandboxing, plist generation, plist path).
#   2. Add the "Stamp Build Date" run-script build phase.
#   3. Remove Info.plist from Copy Bundle Resources.
#   4. Add the AppSubsystem Swift Package dependency.

xcode_project_bundle=$(find . -maxdepth 1 -name "*.xcodeproj" -print -quit)

if [[ -z "$xcode_project_bundle" ]]; then
    log_warning "No .xcodeproj found – configure project settings manually (see README)."
elif ! command -v python3 &>/dev/null; then
    log_warning "python3 not found – configure project settings manually (see README)."
else
    project_file_path="$xcode_project_bundle/project.pbxproj"

    if [[ -f "$project_file_path" ]]; then
        python3 - "$project_file_path" "$target_name" << 'PYTHON_SCRIPT'
import re
import sys
import uuid


# ===================================================================
# Read project file
# ===================================================================

project_file_path = sys.argv[1]
target_name = sys.argv[2]

with open(project_file_path, "r") as file_handle:
    project_content = file_handle.read()

original_content = project_content
status_messages = []

# Terminal formatting (ANSI codes, safe for any terminal).
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
CYAN = "\033[36m"

def log_created(description):
    status_messages.append(f"  {GREEN}✓{RESET}  Created   {description}")

def log_updated(description):
    status_messages.append(f"  {GREEN}✓{RESET}  Updated   {description}")

def log_skipped(description):
    status_messages.append(f"  {DIM}–  Skipped   {description}{RESET}")

def log_detail(description):
    status_messages.append(f"              {description}")

def generate_uuid():
    """Generate a 24-character uppercase hex UUID for use in pbxproj."""
    return uuid.uuid4().hex[:24].upper()


# ===================================================================
# 1. Build Settings
# ===================================================================
#
# Three settings must be configured:
#
#   ENABLE_USER_SCRIPT_SANDBOXING = NO
#       Allows the run-script build phase to write to the Info.plist.
#
#   GENERATE_INFOPLIST_FILE = NO
#       Tells Xcode to use the hand-authored Info.plist rather than
#       generating one automatically.
#
#   INFOPLIST_FILE = "<target>/Info.plist"
#       Points the build system to the correct plist path.

info_plist_build_setting_value = f"{target_name}/Info.plist"
build_settings_changed = False

if "ENABLE_USER_SCRIPT_SANDBOXING = YES" in project_content:
    project_content = project_content.replace(
        "ENABLE_USER_SCRIPT_SANDBOXING = YES",
        "ENABLE_USER_SCRIPT_SANDBOXING = NO",
    )
    build_settings_changed = True

if "GENERATE_INFOPLIST_FILE = YES" in project_content:
    project_content = project_content.replace(
        "GENERATE_INFOPLIST_FILE = YES",
        "GENERATE_INFOPLIST_FILE = NO",
    )
    build_settings_changed = True

# Check for a standalone INFOPLIST_FILE setting. A negative lookbehind
# prevents matching against GENERATE_INFOPLIST_FILE, which contains
# INFOPLIST_FILE as a substring.
has_standalone_infoplist_file = re.search(
    r'(?<!GENERATE_)INFOPLIST_FILE\s*=', project_content
)

if has_standalone_infoplist_file:
    # Replace existing standalone INFOPLIST_FILE values, leaving
    # GENERATE_INFOPLIST_FILE untouched via the negative lookbehind.
    project_content = re.sub(
        r'(?<!GENERATE_)INFOPLIST_FILE = [^;]*;',
        f'INFOPLIST_FILE = "{info_plist_build_setting_value}";',
        project_content,
    )
    build_settings_changed = True
elif "GENERATE_INFOPLIST_FILE" in project_content:
    # No standalone INFOPLIST_FILE exists yet. Inject one immediately
    # after each GENERATE_INFOPLIST_FILE line.
    project_content = re.sub(
        r'(GENERATE_INFOPLIST_FILE = [^;]*;)',
        rf'\1\n\t\t\t\tINFOPLIST_FILE = "{info_plist_build_setting_value}";',
        project_content,
    )
    build_settings_changed = True

if build_settings_changed:
    log_updated("Build settings")
    log_detail(f"ENABLE_USER_SCRIPT_SANDBOXING = NO")
    log_detail(f"GENERATE_INFOPLIST_FILE = NO")
    log_detail(f'INFOPLIST_FILE = "{info_plist_build_setting_value}"')
else:
    log_skipped("Build settings (already configured)")


# ===================================================================
# 2. Run Script Build Phase ("Stamp Build Date")
# ===================================================================
#
# This build phase increments the build number and stamps the current
# date into the Info.plist on every compile. On the very first build
# it also records the initial compile date.

build_phase_name = "Stamp Build Date"

if build_phase_name in project_content:
    log_skipped(f"Run Script build phase (already exists)")
else:
    build_phase_uuid = generate_uuid()

    shell_script_source = (
        "#!/bin/bash\n"
        "\n"
        "set -e\n"
        'PLIST="$INFOPLIST_FILE"\n'
        "\n"
        "# Increment build number\n"
        'BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST")\n'
        "BUILD_NUMBER=$((BUILD_NUMBER + 1))\n"
        "\n"
        "# Current build timestamp\n"
        "BUILD_DATE=$(date +%s)\n"
        "\n"
        "# Update CFBuildDate and CFBundleVersion\n"
        '/usr/libexec/PlistBuddy -c "Set :CFBuildDate $BUILD_DATE" "$PLIST"\n'
        '/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$PLIST"\n'
        "\n"
        "# Conditionally set CFFirstCompileDate\n"
        'PLACEHOLDER_FIRST_COMPILE_DATE="1183100400"\n'
        "CURRENT_FIRST_COMPILE_DATE=$("
        '/usr/libexec/PlistBuddy -c "Print :CFFirstCompileDate" "$PLIST"'
        ' 2>/dev/null || echo "")\n'
        "\n"
        'if [[ "$CURRENT_FIRST_COMPILE_DATE" == "$PLACEHOLDER_FIRST_COMPILE_DATE" ]]; then\n'
        '  /usr/libexec/PlistBuddy -c "Set :CFFirstCompileDate $BUILD_DATE" "$PLIST"\n'
        "fi\n"
    )

    escaped_shell_script = (
        shell_script_source
        .replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
    )

    build_phase_definition = (
        f"\t\t{build_phase_uuid} /* {build_phase_name} */ = {{\n"
        f"\t\t\tisa = PBXShellScriptBuildPhase;\n"
        f"\t\t\talwaysOutOfDate = 1;\n"
        f"\t\t\tbuildActionMask = 2147483647;\n"
        f"\t\t\tfiles = (\n"
        f"\t\t\t);\n"
        f"\t\t\tinputFileListPaths = (\n"
        f"\t\t\t);\n"
        f"\t\t\tinputPaths = (\n"
        f"\t\t\t);\n"
        f'\t\t\tname = "{build_phase_name}";\n'
        f"\t\t\toutputFileListPaths = (\n"
        f"\t\t\t);\n"
        f"\t\t\toutputPaths = (\n"
        f"\t\t\t);\n"
        f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        f"\t\t\tshellPath = /bin/bash;\n"
        f'\t\t\tshellScript = "{escaped_shell_script}";\n'
        f"\t\t\tshowEnvVarsInLog = 0;\n"
        f"\t\t}};\n"
    )

    section_end_marker = "/* End PBXShellScriptBuildPhase section */"
    section_begin_marker = "/* Begin PBXShellScriptBuildPhase section */"

    if section_end_marker in project_content:
        project_content = project_content.replace(
            section_end_marker,
            build_phase_definition + section_end_marker,
        )
    else:
        sources_section_begin = "/* Begin PBXSourcesBuildPhase section */"
        new_section = (
            f"{section_begin_marker}\n"
            f"{build_phase_definition}"
            f"{section_end_marker}\n\n"
        )
        project_content = project_content.replace(
            sources_section_begin,
            new_section + sources_section_begin,
        )

    # Register the build phase UUID in the native target's buildPhases list.
    native_target_pattern = re.compile(
        r"(/\* Begin PBXNativeTarget section \*/.*?)"
        r"(buildPhases\s*=\s*\()(.*?)(\);)",
        re.DOTALL,
    )
    native_target_match = native_target_pattern.search(project_content)

    if native_target_match:
        existing_phases = native_target_match.group(3).rstrip()
        new_phase_entry = f"\n\t\t\t\t{build_phase_uuid} /* {build_phase_name} */,"
        replacement = (
            native_target_match.group(1)
            + native_target_match.group(2)
            + existing_phases
            + new_phase_entry
            + "\n\t\t\t"
            + native_target_match.group(4)
        )
        project_content = (
            project_content[:native_target_match.start()]
            + replacement
            + project_content[native_target_match.end():]
        )

    log_created(f"Run Script build phase ({build_phase_name})")


# ===================================================================
# 3. Remove Info.plist from Copy Bundle Resources
# ===================================================================
#
# Two Xcode project formats must be handled:
#
#   Legacy format (Xcode 15 and earlier):
#       Files appear as explicit PBXBuildFile entries with comments
#       like "/* Info.plist in Resources */". Drop every such line.
#
#   Synchronized format (Xcode 16+):
#       A PBXFileSystemSynchronizedRootGroup auto-discovers files
#       from disk. There are no PBXBuildFile entries to remove.
#       Instead, create a PBXFileSystemSynchronizedBuildFileExceptionSet
#       that tells Xcode to exclude Info.plist from the target's
#       build phases.

# -- Legacy format: remove explicit "Info.plist in ..." lines -------

filtered_lines = []
did_remove_info_plist_build_file = False

for line in project_content.split('\n'):
    if re.search(r'/\*\s*Info\.plist\s+in\s+', line):
        did_remove_info_plist_build_file = True
        continue
    filtered_lines.append(line)

if did_remove_info_plist_build_file:
    project_content = '\n'.join(filtered_lines)
    log_updated("Removed Info.plist from Copy Bundle Resources")

# -- Synchronized format: add an exception set ----------------------

if 'PBXFileSystemSynchronizedRootGroup' in project_content:
    already_excluded = re.search(
        r'membershipExceptions\s*=\s*\([^)]*Info\.plist',
        project_content,
        re.DOTALL,
    )

    if not already_excluded:
        # Locate the synchronized root group UUID for the target.
        synchronized_group_pattern = re.compile(
            r'([A-Fa-f0-9]{24})\s*/\*\s*'
            + re.escape(target_name)
            + r'\s*\*/\s*=\s*\{[^}]*'
            r'isa\s*=\s*PBXFileSystemSynchronizedRootGroup',
            re.DOTALL,
        )
        synchronized_group_match = synchronized_group_pattern.search(project_content)

        # Locate the native target UUID.
        native_target_uuid_pattern = re.compile(
            r'([A-Fa-f0-9]{24})\s*/\*\s*'
            + re.escape(target_name)
            + r'\s*\*/\s*=\s*\{[^}]*'
            r'isa\s*=\s*PBXNativeTarget',
            re.DOTALL,
        )
        native_target_uuid_match = native_target_uuid_pattern.search(project_content)

        if synchronized_group_match and native_target_uuid_match:
            synchronized_group_uuid = synchronized_group_match.group(1)
            native_target_uuid = native_target_uuid_match.group(1)
            exception_set_uuid = generate_uuid()

            exception_set_type = "PBXFileSystemSynchronizedBuildFileExceptionSet"
            exception_set_entry = (
                f"\t\t{exception_set_uuid} /* {exception_set_type} */ = {{\n"
                f"\t\t\tisa = {exception_set_type};\n"
                f"\t\t\tmembershipExceptions = (\n"
                f"\t\t\t\tInfo.plist,\n"
                f"\t\t\t);\n"
                f"\t\t\ttarget = {native_target_uuid} /* {target_name} */;\n"
                f"\t\t}};\n"
            )

            # Insert into an existing section, or create a new one.
            exception_section_end = f"/* End {exception_set_type} section */"
            exception_section_begin = f"/* Begin {exception_set_type} section */"
            synchronized_section_begin = "/* Begin PBXFileSystemSynchronizedRootGroup section */"

            if exception_section_end in project_content:
                project_content = project_content.replace(
                    exception_section_end,
                    exception_set_entry + exception_section_end,
                )
            else:
                new_section = (
                    f"{exception_section_begin}\n"
                    f"{exception_set_entry}"
                    f"{exception_section_end}\n\n"
                )
                project_content = project_content.replace(
                    synchronized_section_begin,
                    new_section + synchronized_section_begin,
                )

            # Add the exception reference to the root group's block.
            exception_reference = f"{exception_set_uuid} /* {exception_set_type} */"

            group_block_pattern = re.compile(
                r'(\s*' + re.escape(synchronized_group_uuid)
                + r'\s*/\*.*?\*/\s*=\s*\{)(.*?)(\};)',
                re.DOTALL,
            )
            group_block_match = group_block_pattern.search(project_content)

            if group_block_match:
                prefix = group_block_match.group(1)
                body = group_block_match.group(2)
                suffix = group_block_match.group(3)

                if 'exceptions' in body:
                    body = re.sub(
                        r'(exceptions\s*=\s*\()',
                        rf'\1\n\t\t\t\t{exception_reference},',
                        body,
                        count=1,
                    )
                else:
                    body = (
                        f"\n\t\t\texceptions = (\n"
                        f"\t\t\t\t{exception_reference},\n"
                        f"\t\t\t);"
                        + body
                    )

                project_content = (
                    project_content[:group_block_match.start()]
                    + prefix + body + suffix
                    + project_content[group_block_match.end():]
                )

            log_updated("Excluded Info.plist via synchronized group exception")

if (
    not did_remove_info_plist_build_file
    and 'PBXFileSystemSynchronizedRootGroup' not in project_content
):
    log_skipped("Info.plist not found in Copy Bundle Resources")


# ===================================================================
# 4. Add AppSubsystem Swift Package Dependency
# ===================================================================

repository_url = "https://github.com/grantbrooksgoodman/app-subsystem"
product_name = "AppSubsystem"
package_branch = "main"

if repository_url in project_content:
    log_skipped("AppSubsystem package dependency (already added)")
else:
    package_reference_uuid = generate_uuid()
    product_dependency_uuid = generate_uuid()

    # -- XCRemoteSwiftPackageReference entry -------------------------

    package_reference_entry = (
        f'\t\t{package_reference_uuid} /* XCRemoteSwiftPackageReference "app-subsystem" */ = {{\n'
        f"\t\t\tisa = XCRemoteSwiftPackageReference;\n"
        f'\t\t\trepositoryURL = "{repository_url}";\n'
        f"\t\t\trequirement = {{\n"
        f"\t\t\t\tkind = branch;\n"
        f'\t\t\t\tbranch = {package_branch};\n'
        f"\t\t\t}};\n"
        f"\t\t}};\n"
    )

    package_reference_section_end = "/* End XCRemoteSwiftPackageReference section */"
    package_reference_section_begin = "/* Begin XCRemoteSwiftPackageReference section */"

    if package_reference_section_end in project_content:
        project_content = project_content.replace(
            package_reference_section_end,
            package_reference_entry + package_reference_section_end,
        )
    else:
        configuration_list_begin = "/* Begin XCConfigurationList section */"
        new_section = (
            f"{package_reference_section_begin}\n"
            f"{package_reference_entry}"
            f"{package_reference_section_end}\n\n"
        )
        project_content = project_content.replace(
            configuration_list_begin,
            new_section + configuration_list_begin,
        )

    # -- XCSwiftPackageProductDependency entry -----------------------

    product_dependency_entry = (
        f"\t\t{product_dependency_uuid} /* {product_name} */ = {{\n"
        f"\t\t\tisa = XCSwiftPackageProductDependency;\n"
        f'\t\t\tpackage = {package_reference_uuid}'
        f' /* XCRemoteSwiftPackageReference "app-subsystem" */;\n'
        f"\t\t\tproductName = {product_name};\n"
        f"\t\t}};\n"
    )

    product_dependency_section_end = "/* End XCSwiftPackageProductDependency section */"
    product_dependency_section_begin = "/* Begin XCSwiftPackageProductDependency section */"

    if product_dependency_section_end in project_content:
        project_content = project_content.replace(
            product_dependency_section_end,
            product_dependency_entry + product_dependency_section_end,
        )
    else:
        new_section = (
            f"{product_dependency_section_begin}\n"
            f"{product_dependency_entry}"
            f"{product_dependency_section_end}\n\n"
        )
        if package_reference_section_begin in project_content:
            project_content = project_content.replace(
                package_reference_section_begin,
                new_section + package_reference_section_begin,
            )
        else:
            configuration_list_begin = "/* Begin XCConfigurationList section */"
            project_content = project_content.replace(
                configuration_list_begin,
                new_section + configuration_list_begin,
            )

    # -- Register packageReferences on the PBXProject ---------------

    package_reference_comment = (
        f'{package_reference_uuid}'
        f' /* XCRemoteSwiftPackageReference "app-subsystem" */'
    )

    project_section_pattern = re.compile(
        r'(/\* Begin PBXProject section \*/.*?'
        r'isa\s*=\s*PBXProject;)(.*?)(/\* End PBXProject section \*/)',
        re.DOTALL,
    )
    project_section_match = project_section_pattern.search(project_content)

    if project_section_match:
        project_body = project_section_match.group(2)

        if 'packageReferences' in project_body:
            project_body = re.sub(
                r'(packageReferences\s*=\s*\()',
                rf'\1\n\t\t\t\t{package_reference_comment},',
                project_body,
                count=1,
            )
        else:
            project_body = re.sub(
                r'(targets\s*=\s*\()',
                (
                    f'packageReferences = (\n'
                    f'\t\t\t\t{package_reference_comment},\n'
                    f'\t\t\t);\n'
                    f'\t\t\t\\1'
                ),
                project_body,
                count=1,
            )

        project_content = (
            project_content[:project_section_match.start()]
            + project_section_match.group(1)
            + project_body
            + project_section_match.group(3)
            + project_content[project_section_match.end():]
        )

    # -- Register packageProductDependencies on PBXNativeTarget -----

    product_dependency_comment = f'{product_dependency_uuid} /* {product_name} */'

    target_block_pattern = re.compile(
        r'(/\* Begin PBXNativeTarget section \*/.*?'
        + re.escape(target_name)
        + r'.*?isa\s*=\s*PBXNativeTarget;)(.*?)(\};)',
        re.DOTALL,
    )
    target_block_match = target_block_pattern.search(project_content)

    if target_block_match:
        target_body = target_block_match.group(2)

        if 'packageProductDependencies' in target_body:
            target_body = re.sub(
                r'(packageProductDependencies\s*=\s*\()',
                rf'\1\n\t\t\t\t{product_dependency_comment},',
                target_body,
                count=1,
            )
        else:
            target_body = re.sub(
                r'(productType\s*=\s*[^;]*;)',
                (
                    f'\\1\n\t\t\tpackageProductDependencies = (\n'
                    f'\t\t\t\t{product_dependency_comment},\n'
                    f'\t\t\t);'
                ),
                target_body,
                count=1,
            )

        project_content = (
            project_content[:target_block_match.start()]
            + target_block_match.group(1)
            + target_body
            + target_block_match.group(3)
            + project_content[target_block_match.end():]
        )

    # -- Add PBXBuildFile entry for the Frameworks link -------------

    framework_build_file_uuid = generate_uuid()
    framework_build_file_entry = (
        f"\t\t{framework_build_file_uuid} /* {product_name} in Frameworks */"
        f" = {{isa = PBXBuildFile; "
        f"productRef = {product_dependency_uuid} /* {product_name} */; }};\n"
    )

    build_file_section_end = "/* End PBXBuildFile section */"
    project_content = project_content.replace(
        build_file_section_end,
        framework_build_file_entry + build_file_section_end,
    )

    # Register the build file in the Frameworks build phase.
    frameworks_phase_pattern = re.compile(
        r'(isa\s*=\s*PBXFrameworksBuildPhase;.*?files\s*=\s*\()',
        re.DOTALL,
    )
    frameworks_phase_match = frameworks_phase_pattern.search(project_content)

    if frameworks_phase_match:
        insertion_point = frameworks_phase_match.end()
        framework_file_reference = (
            f"\n\t\t\t\t{framework_build_file_uuid}"
            f" /* {product_name} in Frameworks */,"
        )
        project_content = (
            project_content[:insertion_point]
            + framework_file_reference
            + project_content[insertion_point:]
        )

    log_created(f"AppSubsystem package dependency (branch: {package_branch})")


# ===================================================================
# Write project file
# ===================================================================

if project_content != original_content:
    with open(project_file_path, "w") as file_handle:
        file_handle.write(project_content)

for message in status_messages:
    print(message)

PYTHON_SCRIPT
    else
        echo ""
        log_warning "Could not find $project_file_path – configure project settings manually."
    fi
fi


# ===================================================================
# MARK: - Configure Scheme Environment Variables
# ===================================================================
#
# Xcode schemes live in either xcshareddata/xcschemes (shared) or
# xcuserdata/<user>.xcuserdatad/xcschemes (personal). Modern versions
# of Xcode auto-generate schemes in memory from targets, so no
# .xcscheme file exists on disk until the scheme is shared or edited
# manually. When no file is found, this section creates a minimal
# shared scheme with the required environment variable.

if [[ -n "$xcode_project_bundle" ]] && command -v python3 &>/dev/null; then
    scheme_file_path=""

    # Prefer shared schemes; fall back to user-scoped schemes.
    for candidate_path in \
        "$xcode_project_bundle/xcshareddata/xcschemes/$target_name.xcscheme" \
        "$xcode_project_bundle"/xcuserdata/*/xcschemes/"$target_name.xcscheme"
    do
        if [[ -f "$candidate_path" ]]; then
            scheme_file_path="$candidate_path"
            break
        fi
    done

    # If no scheme exists on disk, prepare a shared scheme path.
    if [[ -z "$scheme_file_path" ]]; then
        shared_schemes_directory="$xcode_project_bundle/xcshareddata/xcschemes"
        mkdir -p "$shared_schemes_directory"
        scheme_file_path="$shared_schemes_directory/$target_name.xcscheme"
    fi

    python3 - "$scheme_file_path" "$target_name" "$xcode_project_bundle" "$project_file_path" << 'PYTHON_SCRIPT'
import os
import re
import sys
import xml.etree.ElementTree as ET


# ===================================================================
# Parse arguments
# ===================================================================

scheme_file_path = sys.argv[1]
target_name = sys.argv[2]
xcode_project_basename = os.path.basename(sys.argv[3])
project_file_path = sys.argv[4]

# Terminal formatting.
GREEN = "\033[32m"
DIM = "\033[2m"
YELLOW = "\033[33m"
RESET = "\033[0m"


# ===================================================================
# Parse or create scheme
# ===================================================================

if os.path.isfile(scheme_file_path):
    tree = ET.parse(scheme_file_path)
    root = tree.getroot()
    did_create_scheme = False
else:
    # Resolve the native target UUID from the project file. This is
    # required to build a valid BuildableReference element.
    target_uuid = None

    if os.path.isfile(project_file_path):
        with open(project_file_path) as file_handle:
            project_content = file_handle.read()

        native_target_match = re.search(
            r'([A-Fa-f0-9]{24})\s*/\*\s*'
            + re.escape(target_name)
            + r'\s*\*/\s*=\s*\{[^}]*isa\s*=\s*PBXNativeTarget',
            project_content,
            re.DOTALL,
        )

        if native_target_match:
            target_uuid = native_target_match.group(1)

    if not target_uuid:
        print(f"  {YELLOW}!{RESET}  Warning   Could not resolve target UUID for scheme creation.")
        print(f"              Set OS_ACTIVITY_MODE manually in Edit Scheme > Run > Environment Variables.")
        sys.exit(0)

    # Construct a minimal shared scheme document.
    root = ET.Element("Scheme", attrib={
        "LastUpgradeVersion": "1600",
        "version": "1.7",
    })

    def create_buildable_reference(parent_element):
        """Append a BuildableReference element to the given parent."""
        reference = ET.SubElement(parent_element, "BuildableReference")
        reference.set("BuildableIdentifier", "primary")
        reference.set("BlueprintIdentifier", target_uuid)
        reference.set("BuildableName", f"{target_name}.app")
        reference.set("BlueprintName", target_name)
        reference.set("ReferencedContainer", f"container:{xcode_project_basename}")
        return reference

    # BuildAction
    build_action = ET.SubElement(root, "BuildAction", attrib={
        "parallelizeBuildables": "YES",
        "buildImplicitDependencies": "YES",
        "buildArchitectures": "Automatic",
    })
    build_action_entries = ET.SubElement(build_action, "BuildActionEntries")
    build_action_entry = ET.SubElement(build_action_entries, "BuildActionEntry", attrib={
        "buildForTesting": "YES",
        "buildForRunning": "YES",
        "buildForProfiling": "YES",
        "buildForArchiving": "YES",
        "buildForAnalyzing": "YES",
    })
    create_buildable_reference(build_action_entry)

    # TestAction
    ET.SubElement(root, "TestAction", attrib={
        "buildConfiguration": "Debug",
        "selectedDebuggerIdentifier": "Xcode.DebuggerFoundation.Debugger.LLDB",
        "selectedLauncherIdentifier": "Xcode.DebuggerFoundation.Launcher.LLDB",
        "shouldUseLaunchSchemeArgsEnv": "YES",
        "shouldAutocreateTestPlan": "YES",
    })

    # LaunchAction
    launch_action = ET.SubElement(root, "LaunchAction", attrib={
        "buildConfiguration": "Debug",
        "selectedDebuggerIdentifier": "Xcode.DebuggerFoundation.Debugger.LLDB",
        "selectedLauncherIdentifier": "Xcode.DebuggerFoundation.Launcher.LLDB",
        "launchStyle": "0",
        "useCustomWorkingDirectory": "NO",
        "ignoresPersistentStateOnLaunch": "NO",
        "debugDocumentVersioning": "YES",
        "debugServiceExtension": "internal",
        "allowLocationSimulation": "YES",
    })
    buildable_product_runnable = ET.SubElement(launch_action, "BuildableProductRunnable", attrib={
        "runnableDebuggingMode": "0",
    })
    create_buildable_reference(buildable_product_runnable)

    # ProfileAction
    ET.SubElement(root, "ProfileAction", attrib={
        "buildConfiguration": "Release",
        "shouldUseLaunchSchemeArgsEnv": "YES",
        "savedToolIdentifier": "",
        "useCustomWorkingDirectory": "NO",
        "debugDocumentVersioning": "YES",
    })

    # AnalyzeAction and ArchiveAction
    ET.SubElement(root, "AnalyzeAction", attrib={
        "buildConfiguration": "Debug",
    })
    ET.SubElement(root, "ArchiveAction", attrib={
        "buildConfiguration": "Release",
        "revealArchiveInOrganizer": "YES",
    })

    tree = ET.ElementTree(root)
    did_create_scheme = True


# ===================================================================
# Inject OS_ACTIVITY_MODE environment variable
# ===================================================================

launch_action_element = root.find("LaunchAction")

if launch_action_element is None:
    print(f"  {YELLOW}!{RESET}  Warning   No LaunchAction found in scheme.")
    sys.exit(0)

environment_variables = launch_action_element.find("EnvironmentVariables")

if environment_variables is None:
    environment_variables = ET.SubElement(launch_action_element, "EnvironmentVariables")

for existing_variable in environment_variables.findall("EnvironmentVariable"):
    if existing_variable.get("key") == "OS_ACTIVITY_MODE":
        print(f"  {DIM}–  Skipped   OS_ACTIVITY_MODE (already set in scheme){RESET}")
        sys.exit(0)

new_environment_variable = ET.SubElement(environment_variables, "EnvironmentVariable")
new_environment_variable.set("key", "OS_ACTIVITY_MODE")
new_environment_variable.set("value", "disable")
new_environment_variable.set("isEnabled", "YES")

ET.indent(tree, space="   ")
tree.write(scheme_file_path, xml_declaration=True, encoding="UTF-8")

if did_create_scheme:
    print(f"  {GREEN}✓{RESET}  Created   Shared scheme with OS_ACTIVITY_MODE = disable")
else:
    print(f"  {GREEN}✓{RESET}  Updated   Scheme: OS_ACTIVITY_MODE = disable")

PYTHON_SCRIPT
fi


# ===================================================================
# MARK: - Complete
# ===================================================================

echo ""
echo "${format_bold}  Configuration complete.${format_reset}"
echo "${format_dim}  Build and run the project to verify the setup.${format_reset}"
echo ""
