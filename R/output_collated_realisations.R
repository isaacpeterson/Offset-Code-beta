#' Plots the results of the Offset Simulator run
#' @param user_output_params user configured plotting parameters to use
#' @param simulation_folder user configured simulation folder to use
#' @param run_number user defined folder
#' @param loglevel logging level to use, for instance futile.logger::INFO
#' @import futile.logger
#' @export

osim.output <- function(user_output_params = NULL, simulation_folder = NULL, loglevel = INFO){
  
  flog.appender(appender.tee('osim.output.log'))
  
  if (is.null(user_output_params)) {
    flog.error('provide plot params file')
    stop()
  } 
  
  output_params = overwrite_current_params(user_output_params, default_params = initialise_default_output_params())
  
  collated_folder = paste0(simulation_folder, '/collated_outputs/')  # LOCATION OF COLLATED FILES
  simulation_params_folder = paste0(simulation_folder, '/simulation_params/')
  
  # read in file with stored param settings to identify plots easier
  param_variants_filename = paste0(simulation_params_folder, 'param_variants.rds')
  if (file.exists(param_variants_filename)){
    param_variants = readRDS(paste0(simulation_params_folder, 'param_variants.rds'))
  }
  
  if (length(output_params$output_plot_folder) == 0){
    output_plot_folder = collated_folder
  } else {
    output_plot_folder = output_params$output_plot_folder
  }
  
  if (output_params$plot_type == 'impacts'){
    output_pdf_filename = paste0(output_plot_folder, '/impacts.pdf')
  } else if (output_params$plot_type == 'outcomes'){
    output_pdf_filename = paste0(output_plot_folder, '/outcomes.pdf')
  }
  
  flog.threshold(loglevel)
  
  # Set the output filename, and open the pdf file for reading
  if (output_params$write_pdf == TRUE){
    flog.info('writing to PDF %s', output_pdf_filename)
    pdf(output_pdf_filename, width = 8.3, height = 11.7)
  }
  
  if (output_params$output_plot == TRUE){
  # write plots to nx * ny subplots
    setup_sub_plots(output_params$nx, output_params$ny, x_space = 5, y_space = 5)
  }
  
  global_params_filename <- paste0(simulation_params_folder, '/global_params.rds')
  if (!file.exists(global_params_filename)){
    flog.error(paste('offsetsim run parameter file not found in ', global_params_filename))
    stop()
  } else {
    flog.info('reading %s', global_params_filename)
    
    # get the parameters values for all scenarios in the run
    global_params = readRDS(global_params_filename)
  }
  
  # get the names of all parameter files, separated into run scenarios
  scenario_filenames <- list.files(path = simulation_params_folder, pattern = '_simulation_params', all.files = FALSE,
                                   full.names = FALSE, recursive = FALSE, ignore.case = FALSE,
                                   include.dirs = FALSE, no.. = FALSE)
  
  # check_plot_options(output_params, global_params, scenario_filenames)
  
  if (!file.exists(output_plot_folder)){
    flog.info('creating output plot folder %s', output_plot_folder)
    dir.create(output_plot_folder)
  }
  
  if ( (class(output_params$scenario_vec) == 'character')){
    if (output_params$scenario_vec == 'all'){
      scenario_vec = 1:length(scenario_filenames)
    }
  } else {
    scenario_vec = output_params$scenario_vec
  }
  
  plot.ctr <- 1

  for (scenario_ind in scenario_vec){
    
    flog.info('_________________________________')
    
    file_to_Read = paste0(simulation_params_folder, '/', scenario_filenames[scenario_ind])
    flog.trace('reading %s', file_to_Read)
    current_simulation_params = readRDS(file_to_Read)
    
    param_inds_to_subset = match(output_params$plot_subset_type, names(current_simulation_params))
    
    if (any(!is.na(param_inds_to_subset)) & all(current_simulation_params[param_inds_to_subset] == output_params$plot_subset_param)) {
      plot_flag = TRUE 
    } else {
      if (length(output_params$plot_subset_type) > 1){
        plot_flag = FALSE
      } else {
        if (output_params$plot_subset_type == 'all'){
          plot_flag = TRUE
        } else {
          plot_flag = FALSE
        }
      }
    } 
    
    if (plot_flag == FALSE){
        flog.trace(' skipping scenario %d', scenario_ind )
    } else {
      
      flog.info('Generating plot %d (scen %d of type: %s)', plot.ctr, scenario_ind, output_params$plot_type)  
      if (file.exists(param_variants_filename)){
        
        # Use this line to dump everthing to the log, with the variable and the value each on a different 
        # line, through will work where a variable has 2 or more values.
        #flog.info(rbind(names(param_variants[[scenario_ind]]), as.vector(param_variants[[scenario_ind]]))) 
        
        # The code below was written to provide nicer loggin output, where each variable and its value(s) 
        # are printed on one line in the log file 
        # Note: this only works for variable that have 1, 2 or 3 values
        
        no.vars <- length(names(param_variants[[scenario_ind]]))
        for( i in 1:no.vars) {
          # if param has 3 values
          if(length(param_variants[[scenario_ind]][[i]])==3){
            flog.info(' %s = (%s, %s, %s)', names(param_variants[[scenario_ind]])[i], param_variants[[scenario_ind]][[i]][1], 
                      param_variants[[scenario_ind]][[i]][2], param_variants[[scenario_ind]][[i]][3])
            # if param has 2 values
          } else if(length(param_variants[[scenario_ind]][[i]])==2){
               flog.info(' %s = (%s, %s)', names(param_variants[[scenario_ind]])[i], param_variants[[scenario_ind]][[i]][1], 
                      param_variants[[scenario_ind]][[i]][2])
          } else {
            flog.info(' %s = %s', names(param_variants[[scenario_ind]])[i], param_variants[[scenario_ind]][[i]] )
          }
        }
        
        
      }
      
      if (class(output_params$features_to_plot) == 'character'){
        features_to_plot = seq(current_simulation_params$feature_num)
      }  else {
        features_to_plot = output_params$features_to_plot
      }
        
      for (feature_ind in features_to_plot){
        current_feature = current_simulation_params$features_to_use_in_simulation[feature_ind]
        collated_filenames = find_collated_files(file_path = collated_folder,
                                                 scenario_string = formatC(scenario_ind, width = output_params$string_width, format = "d", flag = "0"),
                                                 feature_string = formatC(current_feature, width = output_params$string_width, format = "d", flag = "0"),
                                                 output_params$realisation_num)
        
        collated_realisations = bind_collated_realisations(collated_filenames)
        
        if (output_params$print_dev_offset_sites == TRUE){
          sites_used = collated_realisations$sites_used
          stats_to_use = which(unlist(lapply(seq_along(sites_used), function(i) length(unlist(sites_used[[i]]))>0)))
          mean_sites_used = lapply(stats_to_use, function (i) round(mean(unlist( sites_used[[i]] ))))
          
          #flog.info(rbind(names(sites_used[stats_to_use]), mean_sites_used))
          
          # Added code to pring the number of sites used for dev, offsets etc, on one line with the variable name
          flog.info('Mean number of sites used for:')
          for( i in 1:length(names(sites_used[stats_to_use])) ) {
            flog.info(' %s = %s', names(sites_used[stats_to_use])[i], mean_sites_used[[i]] )
          }
          
          
        }
        
        if (output_params$output_plot == TRUE){
          if (output_params$plot_type == 'impacts'){
            plot_impact_set(collated_realisations,
                            current_simulation_params,
                            output_params,
                            global_params,
                            realisation_num = collated_realisations$realisation_num,
                            site_plot_lims = output_params$site_impact_plot_lims_set[[feature_ind]],
                            program_plot_lims = output_params$program_impact_plot_lims_set[[feature_ind]],
                            landscape_plot_lims = output_params$landscape_impact_plot_lims_set[[feature_ind]],
                            feature_ind,
                            output_params$sets_to_plot)
          } else if (output_params$plot_type == 'outcomes'){
            plot_outcome_set(collated_realisations,
                             current_simulation_params,
                             output_params,
                             global_params,
                             realisation_num = collated_realisations$realisation_num,
                             site_plot_lims = output_params$site_outcome_plot_lims_set[[feature_ind]],
                             program_plot_lims = output_params$program_outcome_plot_lims_set[[feature_ind]],
                             landscape_plot_lims = output_params$landscape_outcome_plot_lims_set[[feature_ind]],
                             current_feature,
                             output_params$sets_to_plot)
          }
          plot.ctr <- plot.ctr + 1
          #flog.info(' finished writing plot %d', scenario_ind)
        } 
        
        if (output_params$output_csv_file == TRUE){
          flog.info('writing outputs to csv')
          write.table( data.frame(collated_realisations$program_outcomes$net_outcome), col.names = F, row.names = F, 
                       paste0(collated_folder, 'program_outcomes.csv'), sep=',' )
          write.table( data.frame(collated_realisations$program_scale_impacts$program_total), col.names = F, row.names = F, 
                       paste0(collated_folder, 'program_impacts.csv'), sep=',' )
          write.table( data.frame(collated_realisations$landscape$net_landscape), col.names = F, row.names = F, 
                       paste0(collated_folder, 'landscape_outcomes.csv'), sep=',' )
          write.table( data.frame(collated_realisations$landscape$landscape_impact), col.names = F, row.names = F, 
                       paste0(collated_folder, 'landscape_impacts.csv'), sep=',' )
        }
      } 
      
    }
    
  }
  
  # Close the pdf file for reading
  if (output_params$write_pdf == TRUE) {
    graphics.off()
    flog.info('closing PDF %s', output_pdf_filename)
  }
  flog.info('all done')
}



# find the current simulation folder - the function looks in the base_folder directory if supplied 
# and assumes the current working directory contains the simulation folder otherwise. If the user supplies the
# current run number the function looks for thaht specified folder and looks for the latest run otherwise.

#' @export
find_current_run_folder <- function(base_folder = NULL, run_number = NULL){
  
  #if (!is.null(base_folder) & (length(base_folder) > 0) & (base_folder != 'default')){
  if (!is.null(base_folder)){
    if (base_folder == 'default'){
      simulation_folder = 'simulation_runs/'
    } else {
      simulation_folder = paste0(base_folder, '/simulation_runs/')
    }
  } else { 
    simulation_folder = 'simulation_runs/'
  }
  
  if (!is.null(run_number)){
    current_run = run_number
  } else {
    filenames = list.files(path = simulation_folder, all.files = FALSE,
                           full.names = FALSE, recursive = FALSE, ignore.case = FALSE,
                           include.dirs = FALSE, no.. = FALSE, pattern='^[0-9]{1,45}$')
    current_run = as.numeric(filenames[length(filenames)])
  }
  
  simulation_folder = paste0(simulation_folder, formatC(current_run, width = 5, format = "d", flag = "0"), '/')
  if (!dir.exists(simulation_folder)){
    flog.error('simulation_folder %s does not exist.', simulation_folder)
    stop()
  } else{
    return(simulation_folder)
  }
}

