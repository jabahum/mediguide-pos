#!/bin/bash

# Script to search for entries in the Flutter application translation catalogue
# Usage: ./check_translation.sh [OPTIONS] "search_term"
# Supports both .tr and .trParams entries

set -e

TRANSLATIONS_DIR="lib/app/translations"
APP_TRANSLATIONS_FILE="$TRANSLATIONS_DIR/app_translations.dart"
EN_US_FILE="$TRANSLATIONS_DIR/en_us.dart"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Search options
SEARCH_MODE="key"  # Default: search by key
EXACT_MATCH=false
CASE_SENSITIVE=false
SHOW_PARAMS=false

# Function to print colored output
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_info() {
    echo -e "${BLUE}$1${NC}"
}

print_header() {
    echo -e "${BOLD}${CYAN}$1${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] \"search_term\""
    echo ""
    echo "OPTIONS:"
    echo "  --key           Search by translation key (default)"
    echo "  --text          Search by translation text content"
    echo "  --params        Show parameters for trParams entries"
    echo "  --exact         Exact match only (no fuzzy matching)"
    echo "  --case          Case-sensitive search"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 \"welcome\"                    # Find keys containing 'welcome'"
    echo "  $0 --text \"error\"               # Find translations containing 'error'"
    echo "  $0 --exact \"welcomeMessage\"     # Exact key match"
    echo "  $0 --case \"Error\"               # Case-sensitive search"
    echo ""
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --key)
                SEARCH_MODE="key"
                shift
                ;;
            --text)
                SEARCH_MODE="text"
                shift
                ;;
            --params)
                SHOW_PARAMS=true
                shift
                ;;
            --exact)
                EXACT_MATCH=true
                shift
                ;;
            --case)
                CASE_SENSITIVE=true
                shift
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
                if [ -z "$SEARCH_TERM" ]; then
                    SEARCH_TERM="$1"
                else
                    print_error "Multiple search terms provided. Use quotes for terms with spaces."
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [ -z "$SEARCH_TERM" ]; then
        print_error "Search term is required"
        show_usage
        exit 1
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

# Function to build grep options (deprecated - replaced with inline)
build_grep_options() {
    local options="-n"  # Line numbers
    
    if [ "$CASE_SENSITIVE" = false ]; then
        options="$options -i"  # Case insensitive
    fi
    
    if [ "$EXACT_MATCH" = false ]; then
        # No additional options needed for fuzzy matching
        :
    fi
    
    echo "$options"
}

# Function to search translation keys
search_keys() {
    local search_term="$1"
    local grep_options="-n"
    if [ "$CASE_SENSITIVE" = false ]; then
        grep_options="$grep_options -i"
    fi
    local pattern
    
    local results
    if [ "$EXACT_MATCH" = true ]; then
        # Search for both getter and function patterns
        local getter_results=$(grep $grep_options "static String get $search_term =>" "$APP_TRANSLATIONS_FILE" 2>/dev/null || true)
        local function_results=$(grep $grep_options "static String $search_term.*Map" "$APP_TRANSLATIONS_FILE" 2>/dev/null || true)
        results="$getter_results"$'\n'"$function_results"
    else
        # Search for both getter and function patterns with fuzzy matching
        local getter_results=$(grep $grep_options "static String get.*$search_term.*=>" "$APP_TRANSLATIONS_FILE" 2>/dev/null || true)
        local function_results=$(grep $grep_options "static String.*$search_term.*Map" "$APP_TRANSLATIONS_FILE" 2>/dev/null || true)
        results="$getter_results"$'\n'"$function_results"
    fi
    
    # Remove empty lines
    results=$(echo "$results" | grep -v '^$' || true)
    
    if [ -n "$results" ]; then
        echo "$results" | while IFS=: read -r line_num line_content; do
            # Extract the key name and type (getter vs function)
            local key=""
            local entry_type="getter"
            local params=""
            
            if echo "$line_content" | grep -q "static String get"; then
                key=$(echo "$line_content" | sed -n 's/.*static String get \([^[:space:]]*\) =>.*/\1/p')
                entry_type="getter"
            elif echo "$line_content" | grep -q "static String.*Map.*String.*params"; then
                key=$(echo "$line_content" | sed -n 's/.*static String \([^(]*\).*/\1/p')
                entry_type="function"
                # Look for parameter comments in previous lines
                local param_line=$(sed -n "$((line_num-1))p" "$APP_TRANSLATIONS_FILE" 2>/dev/null || true)
                if echo "$param_line" | grep -q "/// Parameters:"; then
                    params=$(echo "$param_line" | sed 's/.*Parameters: //')
                fi
            fi
            
            # Find corresponding translation text in en_us.dart
            if [ -n "$key" ]; then
                local translation_line=$(grep "\"$key\":" "$EN_US_FILE" 2>/dev/null || true)
                if [ -n "$translation_line" ]; then
                    # Extract just the translation text and limit to 30 chars for params
                    local translation_text=$(echo "$translation_line" | sed -n 's/.*": "\([^"]*\)".*/\1/p')
                    if [ ${#translation_text} -gt 30 ]; then
                        translation_text="${translation_text:0:30}..."
                    fi
                    
                    if [ "$entry_type" = "function" ]; then
                        if [ "$SHOW_PARAMS" = true ] && [ -n "$params" ]; then
                            echo "{preview: $translation_text, key: AppTranslationKey.$key(), type: trParams, params: [$params]}"
                        else
                            echo "{preview: $translation_text, key: AppTranslationKey.$key(), type: trParams}"
                        fi
                    else
                        echo "{preview: $translation_text, key: AppTranslationKey.$key, type: tr}"
                    fi
                else
                    if [ "$entry_type" = "function" ]; then
                        echo "{preview: [missing translation], key: AppTranslationKey.$key(), type: trParams}"
                    else
                        echo "{preview: [missing translation], key: AppTranslationKey.$key, type: tr}"
                    fi
                fi
            fi
        done
    fi
}

# Function to search translation text content
search_text() {
    local search_term="$1"
    local grep_options="-n"
    if [ "$CASE_SENSITIVE" = false ]; then
        grep_options="$grep_options -i"
    fi
    local pattern
    
    if [ "$EXACT_MATCH" = true ]; then
        pattern="\"[^\"]*\": \"[^\"]*$search_term[^\"]*\""
    else
        pattern="$search_term"
    fi
    
    local results=$(grep $grep_options "$pattern" "$EN_US_FILE" 2>/dev/null || true)
    
    if [ -n "$results" ]; then
        echo "$results" | while IFS=: read -r line_num line_content; do
            # Extract the key and translation text from the line
            local key=$(echo "$line_content" | sed -n 's/[[:space:]]*"\([^"]*\)".*/\1/p')
            local translation_text=$(echo "$line_content" | sed -n 's/.*": "\([^"]*\)".*/\1/p')
            
            if [ -n "$key" ] && [ -n "$translation_text" ]; then
                # Check if this key uses trParams by looking in app_translations.dart
                local entry_type="tr"
                local params=""
                
                if grep -q "static String $key.*Map" "$APP_TRANSLATIONS_FILE"; then
                    entry_type="trParams"
                    # Look for parameter comments
                    local param_line=$(grep -B1 "static String $key.*Map" "$APP_TRANSLATIONS_FILE" | head -1)
                    if echo "$param_line" | grep -q "/// Parameters:"; then
                        params=$(echo "$param_line" | sed 's/.*Parameters: //')
                    fi
                fi
                
                # Check for parameters in text (@param format)
                local text_params=$(echo "$translation_text" | grep -o '@[a-zA-Z][a-zA-Z0-9]*' | sed 's/@//' | sort -u | tr '\n' ',' | sed 's/,$//')
                
                # Limit translation text to 30 chars for params
                if [ ${#translation_text} -gt 30 ]; then
                    translation_text="${translation_text:0:30}..."
                fi
                
                if [ "$entry_type" = "trParams" ]; then
                    if [ "$SHOW_PARAMS" = true ] && [ -n "$params" ]; then
                        echo "{preview: $translation_text, key: AppTranslationKey.$key(), type: trParams, params: [$params]}"
                    elif [ -n "$text_params" ]; then
                        echo "{preview: $translation_text, key: AppTranslationKey.$key(), type: trParams, textParams: [$text_params]}"
                    else
                        echo "{preview: $translation_text, key: AppTranslationKey.$key(), type: trParams}"
                    fi
                else
                    echo "{preview: $translation_text, key: AppTranslationKey.$key, type: tr}"
                fi
            fi
        done
    fi
}

# Function to show summary statistics (removed - not needed for simple output)

# Main execution
main() {
    parse_arguments "$@"
    check_files
    
    case $SEARCH_MODE in
        "key")
            search_keys "$SEARCH_TERM"
            ;;
        "text")
            search_text "$SEARCH_TERM"
            ;;
        *)
            print_error "Invalid search mode: $SEARCH_MODE"
            exit 1
            ;;
    esac
}

# Check if script is being executed (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
