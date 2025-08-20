setBatchMode(true);
close("*");
run("Clear Results");

bg_value = 5;	// background value and clipping value for red and green image. 5 = 5/255 pixel intensity
ratio = 1;	// A/D ratio value. Standard to separate G4 and dsDNA = 1
max = 15;	// maximum pixel intensity (15 = 15/255) used to set brightness and contrast to compare different images

// Get the folder where the script is located
scriptDir = getDirectory("script");

// Define input and output folders relative to the script
main_folder = scriptDir + "/Test_data/";	 //paste the main folder containing all folders with individual images. 
results_folder = scriptDir + "/Test_data_results/"; // paste folder which should contain all image-folders with result images 

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
		
			// A/D difference calculation
		imageCalculator("Subtract create",  title + " (red)",title + " (green)");
		selectWindow("Result of " + title + " (red)");
		rename("Difference_" + title);
		run("Measure");
		run("Yellow");
		setMinAndMax(0, max); //sets contrast/brightness value to compare images
			// Save image
			saveAs("PNG",output + "Difference_" + files[i]);
		
		// FRET RATIO
		run("Ratio Plus", "image1 = ["+ title + " (red)] image2 = ["+ title + " (green)] background1="+ bg_value +" clipping_value1="+ bg_value +" background2="+ bg_value +" clipping_value2="+ bg_value +" multiplication=1");
		selectWindow("Ratio");
		run("Yellow");
			
		// finds infinity pixels due to values divided by zero
		run("Duplicate...", " ");
		selectWindow("Ratio-1");
		setMinAndMax(10000, 1e10);
		run("8-bit");
		run("Apply LUT");
		run("Invert");
		run("Apply LUT");
		imageCalculator("Divide create 32-bit", "Ratio-1","Ratio-1"); // this is a 32-bit image with either zero (infinity pixels) or one
			// removes infinity pixels 
		imageCalculator("Multiply create 32-bit", "Ratio","Result of Ratio-1");
			// Find pixels equal to one due to zero/zero calculations below background+clipping value
		bg_value2 = 0;
		if (bg_value > 1) {
		    bg_value2 = bg_value * 2 - 1;}
		selectWindow(title + " (red)");
		setThreshold(0, bg_value2, "raw");
		run("Convert to Mask");
		selectWindow(title + " (green)");
		setThreshold(0, bg_value2, "raw");
		run("Convert to Mask");
		imageCalculator("AND create 32-bit", ""+ title + " (red)",""+ title + " (green)");
		selectImage("Result of " + title + " (red)");
		run("Invert");
		run("8-bit");
		run("Apply LUT");
		imageCalculator("Divide create 32-bit", "Result of " + title + " (red)","Result of " + title + " (red)");
			// removes pixels equal to one due to zero/zero calculations below background+clipping value
		imageCalculator("Multiply create 32-bit", "Result of Ratio","Result of Result of " + title + " (red)");
			// set A/D ratio threshold
		selectImage("Result of Result of Ratio");
		rename("Ratio_" + title);
		setMinAndMax(ratio, ratio); // or max = max_ratio_value
		run("8-bit");
		run("Apply LUT");
		run("Measure");
			// Save image
			saveAs("PNG",output + "Ratio_" + files[i]);
		
		close("*"); 
	}
}
saveAs("Results", results_folder + "Results.csv");
