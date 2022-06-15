#
set( test_scripts
  atparse.bash
  default_vars.sh
  run_ccpp.sh
  run_regional_noquilt.sh
  run_regional_control.sh
  run_regional_stoch.sh
  rt.sh
  run_test.sh
  run_srw.sh
  job_card
  job_card_orion
)

#
set( machine_envs
  ${CMAKE_CURRENT_SOURCE_DIR}/machines/noaacloud_intel.env
  ${CMAKE_CURRENT_SOURCE_DIR}/machines/noaacloud_aws_intel.env
  ${CMAKE_CURRENT_SOURCE_DIR}/machines/orion_intel.env
  ${CMAKE_CURRENT_SOURCE_DIR}/machines/orion_gnu.env
)

#
set( template_script
  ${CMAKE_CURRENT_SOURCE_DIR}/template/linux.sh.tmp
  ${CMAKE_CURRENT_SOURCE_DIR}/template/config.sh.tmp
  ${CMAKE_CURRENT_SOURCE_DIR}/template/config_ctest.sh.tmp
)

#
set( test_data
  ${CMAKE_CURRENT_SOURCE_DIR}/data/fv3_model_point_noah.nc
  ${CMAKE_CURRENT_SOURCE_DIR}/data/stoch.nml
  ${CMAKE_CURRENT_SOURCE_DIR}/data/tcvit_rsmc_storms.txt
  ${CMAKE_CURRENT_SOURCE_DIR}/data/fort.15
  ${CMAKE_CURRENT_SOURCE_DIR}/data/input.nml
  ${CMAKE_CURRENT_SOURCE_DIR}/data/bal022019_post.dat
  ${CMAKE_CURRENT_SOURCE_DIR}/data/trk_plot.py
)

#
foreach(FILENAME ${test_scripts})
    execute_process( COMMAND ${CMAKE_COMMAND} -E create_symlink
           ${CMAKE_CURRENT_SOURCE_DIR}/${FILENAME}
           ${CMAKE_CURRENT_BINARY_DIR}/${FILENAME} )
endforeach(FILENAME)

execute_process( COMMAND ${CMAKE_COMMAND} -E copy
      ${CMAKE_CURRENT_SOURCE_DIR}/create_case.sh 
      ${CMAKE_CURRENT_BINARY_DIR}/create_case.sh )

#
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/template)
foreach(FILENAME ${template_script})
     get_filename_component(filename ${FILENAME} NAME )
     execute_process( COMMAND ${CMAKE_COMMAND} -E create_symlink
         ${FILENAME}
         ${CMAKE_CURRENT_BINARY_DIR}/template/${filename} )
endforeach()

# machine envs
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/machines)
foreach(FILENAME ${machine_envs})
     get_filename_component(filename ${FILENAME} NAME )
     execute_process( COMMAND ${CMAKE_COMMAND} -E create_symlink
         ${FILENAME}
         ${CMAKE_CURRENT_BINARY_DIR}/machines/${filename} )
endforeach()

#
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/data)
foreach(FILENAME ${test_data})
     get_filename_component(filename ${FILENAME} NAME )
     execute_process( COMMAND ${CMAKE_COMMAND} -E create_symlink
         ${FILENAME}
         ${CMAKE_CURRENT_BINARY_DIR}/data/${filename} )
endforeach()

#
if ( BUILD_CCPP-SCM )
  add_test ( NAME test_ccpp_scm_fv3
             COMMAND bash run_ccpp.sh ${abs_top_srcdir}
             WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/htf )
endif()

#
add_test ( NAME test_fv3_regional_noquilt
           COMMAND bash run_regional_noquilt.sh 
           WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/htf )

#
add_test ( NAME test_fv3_regional_upp
           COMMAND bash run_regional_control.sh 
           WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/htf )
set_tests_properties(test_fv3_regional_upp PROPERTIES TIMEOUT 7200)

#
add_test ( NAME test_fv3_regional_stoch
           COMMAND bash run_regional_stoch.sh 
           WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/htf )
set_tests_properties(test_fv3_regional_stoch PROPERTIES TIMEOUT 7200)

#
add_test ( NAME test_regional_workflow
           COMMAND bash run_srw.sh ${abs_top_srcdir} ${CMAKE_CURRENT_BINARY_DIR}
           WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/htf )
set_tests_properties(test_regional_workflow PROPERTIES TIMEOUT 7200)
