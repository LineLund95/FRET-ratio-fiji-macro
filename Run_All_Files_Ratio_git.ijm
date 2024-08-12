setBatchMode(true);
close("*");
run("Clear Results");

bg_value = 5;	// background value for red and green image. 5 = 5/255 pixel intensity
ratio = 1;	// A/D ratio value. Standard to separate G4 and dsDNA = 1
max = 15;	// maximum pixel intensity (15 = 15/255) used to set brightness and contrast to compare different images

main_folder = "subfolder/folder/" 	//paste the main folder containing all folders with individual images. 
results_folder = "subfolder/folder/"	// paste folder which should contain all image-folders with result images 


// loop that imports and sorts all loaded images, followed by image analysis

exp_folders = getFileList(main_folder); 
exp_folders = Array.sort(exp_folders);

for (j = 0; j < exp_folders.length; j++) {
	input = main_folder+exp_folders[j];
	
	output = results_folder+substring(exp_folders[j], 0, exp_folders[j].length -1)+"_Results/";
	
	files = getFileList(input);
	files = Array.sort(files);	
	File.makeDirectory(output);
	
	for (i = 0; i < files.length; i++) {
		
		// Open file
		open(input + files[i]);
		title = getTitle();
		
		// Make red/green RGB image
		run("Split Channels");
		selectWindow(title + " (red)");
		selectWindow(title + " (green)");
		run("Merge Channels...", "c1=["+ title +" (red)] c2=["+ title +" (green)] keep");
		selectWindow("RGB");
		run("Enhance Contrast", "saturated=0.10");
			// Save image
			saveAs("PNG",output + "Merged_" + files[i]);
		
		// Measure number of green pixels
		selectWindow(title + " (green)");
		run("Duplicate...", " ");
		selectWindow(title + " (green)-1");
		rename(title + "(green)-1");
		setMinAndMax(bg_value, bg_value);
		run("8-bit");
		run("Apply LUT");
		run("Measure");
		
		
		// A/D ratio calculation
		run("Ratio Plus", "image1 = ["+ title + " (red)] image2 = ["+ title + " (green)] background1="+ bg_value +" clipping_value1="+ bg_value +" background2="+ bg_value +" clipping_value2="+ bg_value +" multiplication=1");
		selectWindow("Ratio");
		run("Yellow");
		setMinAndMax(ratio, ratio);	// sets A/D ratio threshold
		selectWindow("Ratio");		
		run("Duplicate...", " ");
		selectWindow("Ratio-1");
		setMinAndMax(10000, 1e10);	//finds all "infinity" pixels
		run("8-bit");
		run("Apply LUT");
		selectWindow("Ratio");
		run("8-bit");
		run("Apply LUT");
		imageCalculator("Subtract create", "Ratio","Ratio-1");	//removes all "infinity" pixels
		selectWindow("Ratio");
		close();
		selectImage("Result of Ratio");
		rename("Ratio_" + title);
		run("Measure");
			// Save image
		saveAs("PNG",output + "Ratio_" + files[i]);
		
			// A/D difference calculation
		imageCalculator("Subtract create",  title + " (red)",title + " (green)");
		selectWindow("Result of " + title + " (red)");
		rename("Difference_" + title);
		run("Measure");
		run("Yellow");
		setMinAndMax(0, max); //sets contrast/brightness value to compare images
			// Save image
			saveAs("PNG",output + "Difference_" + files[i]);
		
		close("*"); 
	}
}
saveAs("Results", results_folder + "Results.csv");
