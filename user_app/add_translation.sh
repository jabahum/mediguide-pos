#!/bin/bash

# Script to add entries to the Flutter application translation catalogue
# Usage: ./add_translation.sh "translationKey" "Translation text"
# For parameters: ./add_translation.sh "translationKey" "Hello @name, welcome to @app" --params "name,app"

set -e

TRANSLATIONS_DIR="lib/app/translations"
APP_TRANSLATIONS_FILE="$TRANSLATIONS_DIR/app_translations.dart"
EN_US_FILE="$TRANSLATIONS_DIR/en_us.dart"

# Variables for parameter handling
HAS_PARAMS=false
PARAM_LIST=""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}Success: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

# Function to parse arguments
parse_arguments() {
    local translation_key=""
    local translation_text=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --params)
                HAS_PARAMS=true
                PARAM_LIST="$2"
                shift 2
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [ -z "$translation_key" ]; then
                    translation_key="$1"
                elif [ -z "$translation_text" ]; then
                    translation_text="$1"
                else
                    print_error "Too many arguments provided"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Export for use in main function
    TRANSLATION_KEY="$translation_key"
    TRANSLATION_TEXT="$translation_text"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 \"translationKey\" \"Translation text\" [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  --params \"param1,param2\"    Specify parameter names for trParams usage"
    echo "  --help, -h                   Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 \"welcomeMessage\" \"Welcome to MediGuide\""
    echo "  $0 \"UserGreeting\" \"Hello @name, welcome!\" --params \"name\""
    echo "  $0 \"loginSuccess\" \"Logged in as @name with email @email\" --params \"name,email\""
    echo ""
}

# Function to validate input
validate_input() {
    if [ -z "$TRANSLATION_KEY" ]; then
        print_error "Translation key is required"
        show_usage
        exit 1
    fi

    if [ -z "$TRANSLATION_TEXT" ]; then
        print_error "Translation text is required"
        show_usage
        exit 1
    fi

    # Check if key contains valid characters (camelCase)
    if [[ ! "$TRANSLATION_KEY" =~ ^[a-z][a-zA-Z0-9]*$ ]]; then
        print_error "Translation key must be in camelCase format (e.g., 'welcomeMessage')"
        exit 1
    fi
    
    # Validate parameters if provided
    if [ "$HAS_PARAMS" = true ]; then
        validate_parameters
    else
        # Check if text contains @markers but no --params specified
        local markers_in_text=$(echo "$TRANSLATION_TEXT" | grep -o '@[a-zA-Z][a-zA-Z0-9]*' || true)
        if [ -n "$markers_in_text" ]; then
            print_warning "Translation text contains @parameter markers but --params was not specified"
            print_warning "The @markers will not work with .tr - consider using --params for .trParams functionality"
        fi
    fi
}

# Function to validate parameters
validate_parameters() {
    if [ -z "$PARAM_LIST" ]; then
        print_error "Parameter list cannot be empty when --params is specified"
        exit 1
    fi
    
    # Check if translation text contains parameters
    local params_in_text=$(echo "$TRANSLATION_TEXT" | grep -o '@[a-zA-Z][a-zA-Z0-9]*' | sed 's/@//' | sort -u | tr '\n' ',' | sed 's/,$//')
    
    if [ -z "$params_in_text" ]; then
        print_warning "Translation text doesn't contain any @parameter markers, but --params was specified"
    else
        local provided_params=$(echo "$PARAM_LIST" | tr ',' '\n' | sort | tr '\n' ',' | sed 's/,$//')
        if [ "$params_in_text" != "$provided_params" ]; then
            print_warning "Parameter mismatch:"
            print_warning "  Found in text: $params_in_text"
            print_warning "  Provided: $provided_params"
        fi
    fi
}

# Function to check if files exist
check_files() {
    if [ ! -f "$APP_TRANSLATIONS_FILE" ]; then
        print_error "File not found: $APP_TRANSLATIONS_FILE"
        exit 1
    fi

    if [ ! -f "$EN_US_FILE" ]; then
        print_error "File not found: $EN_US_FILE"
        exit 1
    fi
}

# Function to check if translation key already exists
check_existing_key() {
    local key="$TRANSLATION_KEY"
    
    # Check for both getter and function formats
    if grep -q "static String get $key =>" "$APP_TRANSLATIONS_FILE" || grep -q "static String $key(" "$APP_TRANSLATIONS_FILE"; then
        print_error "Translation key '$key' already exists in $APP_TRANSLATIONS_FILE"
        exit 1
    fi

    if grep -q "\"$key\":" "$EN_US_FILE"; then
        print_error "Translation key '$key' already exists in $EN_US_FILE"
        exit 1
    fi
}

# Function to escape quotes and special characters in translation text
escape_quotes() {
    local text="$1"
    # Escape double quotes and dollar signs for JSON string
    echo "$text" | sed 's/"/\\"/g' | sed 's/\$/\\\$/g'
}

# Function to add entry to app_translations.dart
add_to_app_translations() {
    local key="$1"
    local new_entry
    
    local temp_file=$(mktemp)
    
    if [ "$HAS_PARAMS" = true ]; then
        # Create function for trParams with parameter names in comments
        local param_names=$(echo "$PARAM_LIST" | tr ',' ' ')
        
        # Insert the comment and function separately
        awk -v comment="  /// Parameters: $param_names" -v func_line="  static String $key(Map<String, String> params) => \"$key\".trParams(params);" '
        /^}$/ && !inserted {
            print comment
            print func_line
            print $0
            inserted = 1
            next
        }
        { print }
        ' "$APP_TRANSLATIONS_FILE" > "$temp_file"
    else
        # Regular tr getter
        local new_entry="  static String get $key => \"$key\".tr;"
        
        # Insert the new entry before the first closing brace (end of AppTranslationKey class)
        awk -v new_line="$new_entry" '
        /^}$/ && !inserted {
            print new_line
            print $0
            inserted = 1
            next
        }
        { print }
        ' "$APP_TRANSLATIONS_FILE" > "$temp_file"
    fi
    
    mv "$temp_file" "$APP_TRANSLATIONS_FILE"
    
    if [ "$HAS_PARAMS" = true ]; then
        print_success "Added trParams function for '$key' to $APP_TRANSLATIONS_FILE"
    else
        print_success "Added getter for '$key' to $APP_TRANSLATIONS_FILE"
    fi
}

# Function to add entry to en_us.dart
add_to_en_us() {
    local key="$1"
    local text="$2"
    local escaped_text=$(escape_quotes "$text")
    local new_entry="  \"$key\": \"$escaped_text\","
    
    # Find the line before the closing brace and insert the new entry
    local temp_file=$(mktemp)
    local total_lines=$(wc -l < "$EN_US_FILE")
    
    # Handle different file structures
    if [ "$total_lines" -le 1 ]; then
        # Empty or single line file - replace entirely
        echo "const Map<String, String> enUS = {" > "$temp_file"
        echo "$new_entry" >> "$temp_file"
        echo "};" >> "$temp_file"
    else
        # Multi-line file - insert before closing brace
        local lines_to_keep=$((total_lines - 1))
        if [ "$lines_to_keep" -gt 0 ]; then
            head -n "$lines_to_keep" "$EN_US_FILE" > "$temp_file"
        else
            touch "$temp_file"
        fi
        echo "$new_entry" >> "$temp_file"
        tail -n 1 "$EN_US_FILE" >> "$temp_file"
    fi
    
    mv "$temp_file" "$EN_US_FILE"
    print_success "Added translation for '$key' to $EN_US_FILE"
}

# Main execution
main() {
    # Parse command line arguments
    parse_arguments "$@"

    echo "Adding translation entry..."
    echo "Key: $TRANSLATION_KEY"
    echo "Text: $TRANSLATION_TEXT"
    if [ "$HAS_PARAMS" = true ]; then
        echo "Parameters: $PARAM_LIST"
    fi
    echo

    validate_input
    check_files
    check_existing_key
    
    # Create backup files
    cp "$APP_TRANSLATIONS_FILE" "$APP_TRANSLATIONS_FILE.backup"
    cp "$EN_US_FILE" "$EN_US_FILE.backup"
    print_warning "Created backup files (.backup extension)"

    # Add entries to both files
    add_to_app_translations "$TRANSLATION_KEY"
    add_to_en_us "$TRANSLATION_KEY" "$TRANSLATION_TEXT"

    echo
    print_success "Translation entry added successfully!"
    if [ "$HAS_PARAMS" = true ]; then
        print_success "You can now use AppTranslationKey.$TRANSLATION_KEY({'param': 'value'}) in your code"
        echo -e "${BLUE}Usage example:${NC}"
        echo "  Text(AppTranslationKey.$TRANSLATION_KEY({'name': 'John', 'email': 'john@example.com'}))"
    else
        print_success "You can now use AppTranslationKey.$TRANSLATION_KEY in your code"
    fi
    
    # Clean up backup files on success
    rm "$APP_TRANSLATIONS_FILE.backup" "$EN_US_FILE.backup"
}

# Check if script is being executed (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi



