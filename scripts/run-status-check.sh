#!/bin/bash

##############################################################################
# Infrastructure Status Check Launcher
# 
# Interactive menu to run all status check scripts
# Provides easy access to comprehensive, quick, and metrics-based checks
#
# Usage: ./run-status-check.sh
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
CYAN='\033[0;36m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Functions
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║     INFRASTRUCTURE STATUS CHECK LAUNCHER                       ║"
    echo "║                                                                ║"
    echo "║  Project Nebula - Complete Infrastructure Monitoring          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_menu() {
    echo ""
    echo -e "${BLUE}Select a check to run:${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} Quick Status (⚡ ~3 seconds)"
    echo "   • At-a-glance infrastructure status"
    echo "   • Perfect for daily checks and CI/CD pipelines"
    echo ""
    echo -e "${GREEN}2)${NC} Complete Status (📋 ~15 seconds)"
    echo "   • Detailed breakdown of all components"
    echo "   • Best for troubleshooting and diagnostics"
    echo ""
    echo -e "${GREEN}3)${NC} Health Metrics (📊 ~25 seconds)"
    echo "   • Performance and resource analysis"
    echo "   • Includes health scoring system"
    echo ""
    echo -e "${GREEN}4)${NC} All Checks (🔄 sequential)"
    echo "   • Run all three checks in sequence"
    echo ""
    echo -e "${GREEN}5)${NC} Documentation"
    echo "   • View script documentation"
    echo ""
    echo -e "${GREEN}0)${NC} Exit"
    echo ""
    echo -n "Enter your choice [0-5]: "
}

run_check() {
    local script=$1
    local display_name=$2
    
    if [ ! -f "$script" ]; then
        echo -e "${RED}✗ Error: $script not found${NC}"
        return 1
    fi
    
    if [ ! -x "$script" ]; then
        echo -e "${YELLOW}Making $script executable...${NC}"
        chmod +x "$script"
    fi
    
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Running: $display_name${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    
    "$script"
    
    return 0
}

run_all_checks() {
    echo -e "\n${CYAN}Running all checks in sequence...${NC}"
    echo -e "${YELLOW}This will take approximately 45 seconds${NC}\n"
    
    # Quick Status
    echo -e "${BLUE}1/3 - Running Quick Status...${NC}"
    run_check "./quick-status.sh" "Quick Status" || return 1
    
    echo -e "\n${YELLOW}Press Enter to continue to Complete Status...${NC}"
    read
    
    # Complete Status  
    echo -e "${BLUE}2/3 - Running Complete Status...${NC}"
    run_check "./check-complete-status.sh" "Complete Status" || return 1
    
    echo -e "\n${YELLOW}Press Enter to continue to Health Metrics...${NC}"
    read
    
    # Health Metrics
    echo -e "${BLUE}3/3 - Running Health Metrics...${NC}"
    run_check "./health-metrics.sh" "Health Metrics" || return 1
    
    echo -e "\n${GREEN}✓ All checks completed!${NC}"
}

show_documentation() {
    clear
    show_banner
    
    if [ -f "STATUS_CHECK_README.md" ]; then
        less STATUS_CHECK_README.md
    elif [ -f "../STATUS_CHECK_README.md" ]; then
        less ../STATUS_CHECK_README.md
    else
        echo -e "${RED}✗ Documentation file not found${NC}"
    fi
}

show_summary() {
    clear
    show_banner
    
    if [ -f "../SCRIPTS_SUMMARY.md" ]; then
        less ../SCRIPTS_SUMMARY.md
    else
        echo -e "${RED}✗ Summary file not found${NC}"
    fi
}

show_shortcuts() {
    echo ""
    echo -e "${YELLOW}💡 Keyboard Shortcuts in 'less':${NC}"
    echo "   • Space: Next page"
    echo "   • b: Previous page"
    echo "   • g: Go to beginning"
    echo "   • G: Go to end"
    echo "   • /: Search"
    echo "   • q: Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_banner
        
        # Check if scripts exist and are executable
        QUICK_CHECK="./quick-status.sh"
        COMPLETE_CHECK="./check-complete-status.sh"
        HEALTH_METRICS="./health-metrics.sh"
        
        # Show status of scripts
        echo -e "${BLUE}Script Status:${NC}"
        [ -x "$QUICK_CHECK" ] && echo -e "  ${GREEN}✓${NC} Quick Status script ready" || echo -e "  ${YELLOW}⚠${NC} Quick Status script needs permission"
        [ -x "$COMPLETE_CHECK" ] && echo -e "  ${GREEN}✓${NC} Complete Status script ready" || echo -e "  ${YELLOW}⚠${NC} Complete Status script needs permission"
        [ -x "$HEALTH_METRICS" ] && echo -e "  ${GREEN}✓${NC} Health Metrics script ready" || echo -e "  ${YELLOW}⚠${NC} Health Metrics script needs permission"
        
        show_menu
        read -r choice
        
        case $choice in
            1)
                run_check "$QUICK_CHECK" "Quick Status Check"
                echo -e "\n${YELLOW}Press Enter to return to menu...${NC}"
                read
                ;;
            2)
                run_check "$COMPLETE_CHECK" "Complete Status Check"
                echo -e "\n${YELLOW}Press Enter to return to menu...${NC}"
                read
                ;;
            3)
                run_check "$HEALTH_METRICS" "Health Metrics Check"
                echo -e "\n${YELLOW}Press Enter to return to menu...${NC}"
                read
                ;;
            4)
                run_all_checks
                echo -e "\n${YELLOW}Press Enter to return to menu...${NC}"
                read
                ;;
            5)
                show_banner
                echo -e "${BLUE}Script Documentation & Guides:${NC}\n"
                echo -e "${GREEN}1)${NC} View Script README"
                echo -e "${GREEN}2)${NC} View Scripts Summary"
                echo -e "${GREEN}0)${NC} Return to main menu"
                echo -n "Enter your choice [0-2]: "
                read -r doc_choice
                case $doc_choice in
                    1)
                        show_documentation
                        show_shortcuts
                        ;;
                    2)
                        show_summary
                        show_shortcuts
                        ;;
                    0)
                        ;;
                    *)
                        echo -e "${RED}Invalid choice${NC}"
                        sleep 2
                        ;;
                esac
                ;;
            0)
                clear
                echo -e "${GREEN}Thank you for using Infrastructure Status Checker!${NC}"
                echo -e "${BLUE}For more information, see: SCRIPTS_SUMMARY.md${NC}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}✗ Invalid choice. Please enter 0-5.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main
fi
