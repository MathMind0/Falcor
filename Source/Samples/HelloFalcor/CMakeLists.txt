add_falcor_executable(HelloFalcor)

target_sources(HelloFalcor PRIVATE
    HelloFalcor.cpp
    HelloFalcor.h
)

target_copy_shaders(HelloFalcor Samples/HelloFalcor)

target_source_group(HelloFalcor "Samples")
