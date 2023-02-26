# CMakeList.txt : CMake project for proxyFESVR, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.8)

project ("fesvr")

# Add source to this project's executable.
add_executable (
	fesvr
	"main.cpp" 
	"fesvr.cpp"
	"fesvr.h"
	"tsi.cpp"
	"tsi.h"
	"../rs232/Rs232.cpp"
	"../rs232/Rs232.h"
	
)

if (CMAKE_VERSION VERSION_GREATER 3.12)
  set_property(TARGET fesvr PROPERTY CXX_STANDARD 11)
endif()
