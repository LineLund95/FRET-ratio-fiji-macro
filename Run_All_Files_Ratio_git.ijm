close("*");
run("Clear Results");

bg_values = 8;
bg_values_offset = 1;

main_folder = "../main_folder/"
results_folder = "../results_folder/"

// folder names for each sample 
exp_folders = getFileList(main_folder); 
exp_folders = Array.sort(exp_folders);


max_ratio_folder = newArray(exp_folders.length); // array for maximum ratio values for each experiment folder
max_difference_folder = newArray(exp_folders.length);
for (j = 0; j < exp_folders.length; j++) {
	input = main_folder+exp_folders[j];
	files = getFileList(input);
	files = Array.sort(files);
	
	// loop over files
	ratio_max = newArray(files.length); // array for all ratio values for an individual experiment folder
	difference_max = newArray(files.length);
	for (i = 0; i < files.length; i++) {
		open(input + files[i]);
		title = getTitle();
		index = 4*j+2*i;
		// processing
		run("Split Channels");
		selectWindow(title + " (red)");
		run("Measure");
		bg_values_red = getResult("Mean",index);
		selectWindow(title + " (green)");
		run("Measure");
		bg_values_green = getResult("Mean",index+1);
		bg_value = Array.sort(Array.concat(bg_values_red,bg_values_green));
		bg_value = bg_values;//bg_value[0];
		
		// FRET RATIO and max value
		run("Ratio Plus", "image1 = ["+ title + " (red)] image2 = ["+ title + " (green)] background1="+ bg_value+bg_values_offset +" clipping_value1="+ bg_value+bg_values_offset +" background2="+ bg_value+bg_values_offset +" clipping_value2="+ bg_value+bg_values_offset +" multiplication=1");
		selectWindow("Ratio");
		rename("Ratio_" + title);
		setMinAndMax(1, 1);
		run("8-bit");
		run("Measure");
		index = 4*j+2*i;
		ratio_max[i] = getResult("Max", index+2);
		// FRET DIFFERENCE
		imageCalculator("Subtract create",  title + " (red)",title + " (green)");
		selectWindow("Result of " + title + " (red)");
		rename("Difference_" + title);
		run("Measure");
		difference_max[i] = getResult("Max",index+3);
		close("*");
	}
	ratio_max_sort = Array.sort(ratio_max); // sorted max ratio array for individual experiment folder
	max_ratio_folder[j] = ratio_max_sort[ratio_max_sort.length-1]; // the maximum ratio value for an individual experiment folder
	difference_max_sort = Array.sort(difference_max);
	max_difference_folder[j] = difference_max_sort[difference_max_sort.length-1];
}
max_raio_folder = Array.sort(max_ratio_folder); // sorted array of the maximum ratios for each experiment folders combined
max_ratio_value = max_ratio_folder[max_ratio_folder.length-1]; // the overall maximum ratio value for all folders
max_difference_folder = Array.sort(max_difference_folder);
max_difference_value = max_difference_folder[max_difference_folder.length-1];
saveAs("Results", results_folder + "Results.csv");

for (j = 0; j < exp_folders.length; j++) {
	input = main_folder+exp_folders[j];
	
	output = results_folder+substring(exp_folders[j], 0, exp_folders[j].length -1)+"_Results/";
	
	files = getFileList(input);
	files = Array.sort(files);	
	//output = substring(input, 0, input.length -1) + "_Results/";
	File.makeDirectory(output);
	
	for (i = 0; i < files.length; i++) {
		
		// Open file
		open(input + files[i]);
		title = getTitle();
		
		// processing
		run("Split Channels");
		selectWindow(title + " (red)");
		run("Measure");
		bg_values_red = getResult("Mean",0);
		run("Clear Results");
		selectWindow(title + " (green)");
		run("Measure");
		bg_values_green = getResult("Mean",0);
		bg_value = Array.sort(Array.concat(bg_values_red,bg_values_green));
		bg_value = bg_values;//bg_value[0];
		run("Clear Results");
		
		run("Merge Channels...", "c1=["+ title +" (red)] c2=["+ title +" (green)] keep");
		selectWindow("RGB");
		run("Enhance Contrast", "saturated=0.10");
			// Save image
		saveAs("PNG",output + "Merged_" + files[i]);
		
		// FRET RATIO
		run("Ratio Plus", "image1 = ["+ title + " (red)] image2 = ["+ title + " (green)] background1="+ bg_value+bg_values_offset +" clipping_value1="+ bg_value+bg_values_offset +" background2="+ bg_value+bg_values_offset +" clipping_value2="+ bg_value+bg_values_offset +" multiplication=1");
		selectWindow("Ratio");
		rename("Ratio_" + title);
		run("Yellow");
		setMinAndMax(1, 1); // or max = max_ratio_value
		run("Calibration Bar...", "location=[Upper Right] fill=White label=Black number=5 decimal=0 font=12 zoom=2 overlay");
		run("8-bit");
			// Save image
		saveAs("PNG",output + "Ratio_" + files[i]);
		
			// FRET DIFFERENCE
		imageCalculator("Subtract create",  title + " (red)",title + " (green)");
		selectWindow("Result of " + title + " (red)");
		rename("Difference_" + title);
		run("Yellow");
		setMinAndMax(0, 15); // or max = max_difference_value
		run("Calibration Bar...", "location=[Upper Right] fill=White label=Black number=5 decimal=0 font=12 zoom=2 overlay");
		run("8-bit");
			// Save image
		saveAs("PNG",output + "Difference_" + files[i]);
		
		close("*"); 
	}
}

run("Quit");