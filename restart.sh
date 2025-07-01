#!/bin/bash

# AI MATE - Flexible Service Restart Script
# Usage: ./restart.sh [--ollama] [--backend] [--frontend] [--all]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default flags
RESTART_OLLAMA=false
RESTART_BACKEND=false
RESTART_FRONTEND=false
RESTART_ALL=false

# Function to display usage
show_usage() {
    echo "🔄 AI MATE Service Restart Script"
    echo "================================="
    echo ""
    echo "Usage: ./restart.sh [options]"
    echo ""
    echo "Options:"
    echo "  --ollama     Restart Ollama API server only"
    echo "  --backend    Restart FastAPI backend only"
    echo "  --frontend   Restart React frontend only"
    echo "  --all        Restart all services (default if no options)"
    echo "  --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./restart.sh --backend              # Restart backend only"
    echo "  ./restart.sh --ollama --backend     # Restart Ollama and backend"
    echo "  ./restart.sh --all                  # Restart all services"
    echo "  ./restart.sh                        # Same as --all"
    echo ""
}

# Function to stop a specific service
stop_ollama() {
    echo -e "${YELLOW}📛 Stopping Ollama API server...${NC}"
    pkill -f "ollama serve" 2>/dev/null || true
    pkill -f "ollama" 2>/dev/null || true
    lsof -ti:11434 | xargs kill -9 2>/dev/null || true
    sleep 2
    echo -e "${GREEN}✅ Ollama stopped${NC}"
}

stop_backend() {
    echo -e "${YELLOW}📛 Stopping FastAPI backend...${NC}"
    pkill -f "uvicorn app.main:app" 2>/dev/null || true
    pkill -f "python -m uvicorn" 2>/dev/null || true
    lsof -ti:8000 | xargs kill -9 2>/dev/null || true
    sleep 2
    echo -e "${GREEN}✅ Backend stopped${NC}"
}

stop_frontend() {
    echo -e "${YELLOW}📛 Stopping React frontend...${NC}"
    pkill -f "react-scripts start" 2>/dev/null || true
    pkill -f "npm start" 2>/dev/null || true
    lsof -ti:3000 | xargs kill -9 2>/dev/null || true
    sleep 2
    echo -e "${GREEN}✅ Frontend stopped${NC}"
}

# Function to start a specific service
start_ollama() {
    echo -e "${BLUE}🚀 Starting Ollama API server...${NC}"
    
    # Check if Ollama is installed
    if ! command -v ollama &> /dev/null; then
        echo -e "${RED}❌ Ollama is not installed${NC}"
        echo -e "${CYAN}ℹ️  Run ./setup_ollama.sh to install Ollama first${NC}"
        return 1
    fi
    
    ollama serve > /dev/null 2>&1 &
    OLLAMA_PID=$!
    sleep 3
    
    if ps -p $OLLAMA_PID > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Ollama API server started (PID: $OLLAMA_PID)${NC}"
        echo -e "${CYAN}🤖 Ollama API: http://localhost:11434${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to start Ollama API server${NC}"
        return 1
    fi
}

start_backend() {
    echo -e "${BLUE}🚀 Starting FastAPI backend...${NC}"
    
    # Check if backend directory exists
    if [ ! -d "backend" ]; then
        echo -e "${RED}❌ Backend directory not found${NC}"
        return 1
    fi
    
    # Check if virtual environment exists
    if [ ! -f "backend/venv/bin/activate" ]; then
        echo -e "${RED}❌ Python virtual environment not found${NC}"
        echo -e "${CYAN}ℹ️  Run: cd backend && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt${NC}"
        return 1
    fi
    
    cd backend
    source venv/bin/activate
    python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload > /dev/null 2>&1 &
    BACKEND_PID=$!
    cd ..
    sleep 3
    
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend server started (PID: $BACKEND_PID)${NC}"
        echo -e "${CYAN}🔧 Backend API: http://localhost:8000${NC}"
        echo -e "${CYAN}📋 API Docs: http://localhost:8000/docs${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to start backend server${NC}"
        return 1
    fi
}

start_frontend() {
    echo -e "${BLUE}🚀 Starting React frontend...${NC}"
    
    # Check if frontend directory exists
    if [ ! -d "frontend" ]; then
        echo -e "${RED}❌ Frontend directory not found${NC}"
        return 1
    fi
    
    # Check if node_modules exists
    if [ ! -d "frontend/node_modules" ]; then
        echo -e "${YELLOW}⚠️  Node modules not found, installing...${NC}"
        cd frontend
        npm install
        cd ..
    fi
    
    cd frontend
    npm start > /dev/null 2>&1 &
    FRONTEND_PID=$!
    cd ..
    sleep 5
    
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend server started (PID: $FRONTEND_PID)${NC}"
        echo -e "${CYAN}📱 Frontend: http://localhost:3000${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to start frontend server${NC}"
        return 1
    fi
}

# Function to check service status
check_service_status() {
    echo -e "${BLUE}📊 Service Status:${NC}"
    
    # Check Ollama
    if pgrep -f "ollama serve" > /dev/null; then
        echo -e "   🤖 Ollama:   ${GREEN}Running${NC}"
    else
        echo -e "   🤖 Ollama:   ${RED}Stopped${NC}"
    fi
    
    # Check Backend
    if pgrep -f "uvicorn app.main:app" > /dev/null; then
        echo -e "   🔧 Backend:  ${GREEN}Running${NC}"
    else
        echo -e "   🔧 Backend:  ${RED}Stopped${NC}"
    fi
    
    # Check Frontend
    if pgrep -f "react-scripts start" > /dev/null || pgrep -f "npm start" > /dev/null; then
        echo -e "   📱 Frontend: ${GREEN}Running${NC}"
    else
        echo -e "   📱 Frontend: ${RED}Stopped${NC}"
    fi
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ollama)
            RESTART_OLLAMA=true
            shift
            ;;
        --backend)
            RESTART_BACKEND=true
            shift
            ;;
        --frontend)
            RESTART_FRONTEND=true
            shift
            ;;
        --all)
            RESTART_ALL=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        --status)
            check_service_status
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# If no specific service is selected, restart all
if [ "$RESTART_OLLAMA" = false ] && [ "$RESTART_BACKEND" = false ] && [ "$RESTART_FRONTEND" = false ] && [ "$RESTART_ALL" = false ]; then
    RESTART_ALL=true
fi

# If --all is specified, restart everything
if [ "$RESTART_ALL" = true ]; then
    RESTART_OLLAMA=true
    RESTART_BACKEND=true
    RESTART_FRONTEND=true
fi

echo -e "${CYAN}🔄 AI MATE Service Restart${NC}"
echo "=========================="

# Show current status
check_service_status

# Stop services in reverse order (frontend -> backend -> ollama)
if [ "$RESTART_FRONTEND" = true ]; then
    stop_frontend
fi

if [ "$RESTART_BACKEND" = true ]; then
    stop_backend
fi

if [ "$RESTART_OLLAMA" = true ]; then
    stop_ollama
fi

echo ""

# Start services in correct order (ollama -> backend -> frontend)
STARTUP_SUCCESS=true

if [ "$RESTART_OLLAMA" = true ]; then
    if ! start_ollama; then
        STARTUP_SUCCESS=false
    fi
    echo ""
fi

if [ "$RESTART_BACKEND" = true ]; then
    if ! start_backend; then
        STARTUP_SUCCESS=false
    fi
    echo ""
fi

if [ "$RESTART_FRONTEND" = true ]; then
    if ! start_frontend; then
        STARTUP_SUCCESS=false
    fi
    echo ""
fi

# Final status
if [ "$STARTUP_SUCCESS" = true ]; then
    echo -e "${GREEN}🎉 Service restart completed successfully!${NC}"
    echo ""
    check_service_status
    echo -e "${CYAN}💡 Use './restart.sh --status' to check service status anytime${NC}"
else
    echo -e "${RED}❌ Some services failed to start${NC}"
    echo ""
    check_service_status
    echo -e "${CYAN}💡 Check the error messages above and try again${NC}"
    exit 1
fi 