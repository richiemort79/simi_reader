//Reading Simi files

//Simi records tw0 files .sbd and .sbc

//From the Simi manual:

//Explanation of the header contibuted by Bruno Vellutini
//https://github.com/nelas/simi.py

//3.1 .sbd and .sbc
//A SIMI°BioCell project consists of two files. All created data of a project are
//stored in a text file .sbd. The .sbc file contains information of the
//corresponding disc and settings of the last lineage session as window size etc. 

/////////////////////////////////////////////////////////////////////////////////////////////////////

//### Data v4.00 ####################################################

//# Header: # # # # # # #
//SIMI*BIOCELL
//400
//---
//# # # # # # # # # # # #

//SIMI*BIOCELL = magic ID string
//400          = file version 4.00
//---          = separator


//# Cell: # # # # # # # #
//<free 3D cells count>
//<start frame> <end frame> <x> <y> <level> <comment>     <= *count
//---
//<start cells count> <start time>
//<start generation>                                      <= *count
//---
//<cells left count> <"right> <active cell left> <"right> <gen.name1>
//<gen.time of birth sec.> <g.level> <g.wildtype> <g.color> <g.name2>
//<birth frm> <mitosis lvl> <wildtype> <size> <shape> <color> <name>
//<coordinates count> <cell comment>
//<frame> <x> <y> <level> <size> <shape> <coord.comment>  <= *count
//---
//# # # # # # # # # # # #

//<start ...> values are not used yet (for later implementation)
//<color> is a real hexadecimal RGB value (e.g. 00ff00 for green)
//<size> and <shape> are internal values of BioCell
//<coordinates> are real pixels

//###################################################################

/////////////////////////////////////////////////////////////////////////////////////////////////////

//each cell entry is seperated by "---"
//read the .txt file a line at a time


pathfile=File.openDialog("Choose the file to Open:");

process(pathfile);

///////////////////////////////////////////////////////////////////Functions here///////////////////////////////////////////////////////////////////////////

function process(pathfile) {

names = split(pathfile, "/");
nl=names.length;
name=names[nl-2]+"_"+names[nl-1];
nam=split(name, ".");
na=name;

filestring=File.openAsString(pathfile); 
rows=split(filestring, "\n"); 

quad = "??"; 

//Define the arrays here
embryo=newArray();//
quadrant=newArray();//
cell_name=newArray(); 
length=newArray();//the number of x,y,z entries for the cell
start_frame=newArray();
start_x=newArray();
start_y=newArray();
start_z=newArray();
parent=newArray();//
fate=newArray();//

for(i=6; i<rows.length; i++) { //ignore first 7 lines as these are the header

	columns=split(rows[i]," "); 
	
	if ((columns[0] == "---") && (i < rows.length-1)) {//New Entry Found
		columns=split(rows[i+1]," ");
		columns1=split(rows[i+2]," ");
		columns2=split(rows[i+3]," ");
		columns3=split(rows[i+5]," ");
		columns4=split(rows[i+4]," ");	
		
				if (columns3[0] == "---") {	} else { //there is an entry for x, y, z

			embryo = Array.concat(embryo, na);
			quadrant = Array.concat(quadrant, quad);
		    cell_name = Array.concat(cell_name, columns[4]);//Gets the name of the cell	
		    
		    start_frame = Array.concat(start_frame, columns2[0]);//Gets the starting frame of the cell
		    length = Array.concat(length, columns4[0]);

		if (columns1.length > 4) {						//Gets the parent cell if there is one defined
			parent = Array.concat(parent, columns1[4]);
			} else {
				parent = Array.concat(parent, "None");
			}
			
			start_x = Array.concat(start_x, columns3[1]);
			start_y = Array.concat(start_y, columns3[2]);
			start_z = Array.concat(start_z, columns3[3]);
		}
	}
}

//draws the summary table
 requires("1.38m");
    title1 = "Lineage_Summary_Table";
    title2 = "["+title1+"]";
    ptab = title2;
    if (isOpen(title1)) {
    }
    else {
        if (getVersion>="1.41g")
            run("Table...", "name="+title2+" width=1000 height=300");
        else
            run("New... ", "name="+title2+" type=Table width=250 height=600");
        print(ptab,"\\Headings:Embryo\tCell\tLevel\tTc (mins)\tSeed?\tFlag");
    }
   
//the x positions of the nodes in the tree are fixed to a corresponding node (let a or 1 = left and p 04 " = right in the names)
x_index = newArray(10,20,30,40,50,60,70,80,90,100,110,120,130,140,150,160,170,180,190,200,210,220,230,240,250,260,270,280,290,300,310,320,330,340,350,360,370,380,390,400,410,420,430,440,450,460,470,480,490,500,510,520,530,540,550,560,570,580,590,600,610,620);
nodes_2 = newArray("aaaaa","aaaa","aaaap","aaa","aaapa","aaap","aaapp","aa","aapaa","aapa","aapap","aap","aappa","aapp","aappp","a","apaaa","apaa","apaap","apa","apapa","apap","apapp","ap","appaa","appa","appap","app","apppa","appp","apppp","paaaa","paaa","paaap","paa","paapa","paap","paapp","pa","papaa","papa","papap","pap","pappa","papp","pappp","p","ppaaa","ppaa","ppaap","ppa","ppapa","ppap","ppapp","pp","pppaa","pppa","pppap","ppp","ppppa","pppp","ppppp");
nodes_1 = newArray("11111","1111","11112","111","11121","1112","11122","11","11211","1121","11212","112","11221","1122","11222","1","12111","1211","12112","121","12121","1212","12122","12","12211","1221","12212","122","12221","1222","12222","21111","2111","21112","211","21121","2112","21122","21","21211","2121","21212","212","21221","2122","21222","2","22111","2211","22112","221","22121","2212","22122","22","22211","2221","22212","222","22221","2222","22222");

//the distance between the nodes at each level is therefore also fixed
level_index = newArray(1,2,3,4,5,6,7,8);
level_distance = newArray(310,160,80,40,20,10,5,2.5);

//determine from the corresponding .sbc file the calibration and the left/right delimiter

//STARTFRAME=0      frame the anlysis starts
//SCANCOUNT=258		at least as long as the recording???
//LEVELCOUNT=13		the number of z frames at each timepoint
//SCANTIME=6000		time between frames in 1/10 sec 6000 = 10 mins

root = substring(pathfile, 0, lengthOf(pathfile)-3);
pathfile2 = root+"sbc";

if (File.exists(pathfile2) == "0") {print("Error: Cannot find corresponding .sbc file!");} else {

filestring2=File.openAsString(pathfile2); 
rows2=split(filestring2, "\n");

//get left in a loop
for (i=0; i<rows2.length; i++) {
	if (lengthOf(rows2[i]) < 5) {} else {
		//print(substring(rows2[i],0,4));
		if (substring(rows2[i],0,4) =="LEFT") {
			result = rows2[i];
			result2 = split(result, "=");
			left = result2[1];
			
     	}
	}
}

//get right in a loop
for (i=0; i<rows2.length; i++) {
	if (lengthOf(rows2[i]) < 5) {} else {
		if (substring(rows2[i],0,5) =="RIGHT") {
			result = rows2[i];
			result2 = split(result, "=");
			right = result2[1];
			
     	}
	}
}

//get the scan time in a loop
for (i=0; i<rows2.length; i++) {
	if (lengthOf(rows2[i]) < 8) {} else {
		if (substring(rows2[i],0,8) =="SCANTIME") {
			result = rows2[i];
			result2 = split(result, "=");
			time = result2[1];		
     	}
	}
}

t_mins = (time)/600;

if (left == "a") {nodes = nodes_2;} else {if (left == 1) {nodes = nodes_1;}}

node_levels = newArray;

for (i=0; i<nodes.length; i++) {
	nlength = lengthOf(nodes[i]);
	node_levels = Array.concat(node_levels, nlength);
}

//get the seed names and level from the list of names seeds are EITHER a single character that is NOT the left or right delimiter
//OR two charcters, the second of which is NOT the left or right delimiter

seeds = newArray();

for (i=0; i<cell_name.length; i++) {
	
	testseed = cell_name[i];
	
	if (lengthOf(testseed) == 1) {seeds = Array.concat(seeds, testseed);} else {

		 name1 = substring(testseed, 1, 2);
		 		
		 if (lengthOf(testseed)!=2) {} else {
					
					if((name1 == left) || (name1 == right)){} else {
						seeds = Array.concat(seeds, testseed);
					} 
			
	 		}
	}
}

if (seeds.length == 0) {print("ERROR: No seeds were found!");} else {

//create an array of seed offsets and colours
cols = newArray("Red", "Blue", "Green", "Black");
seeds_offset = newArray();
seeds_color = newArray();
soff = 0;
scol = "Red";
seeds_offset = Array.concat(seeds_offset, soff);
seeds_color = Array.concat(seeds_color, scol);
cindex=0;

for (i=0; i<seeds.length-1; i++) {
	soff=soff+620;
	if (cindex < 3) {cindex = cindex+1;} else {cindex = 0;}
	scol = cols[cindex];
	seeds_offset = Array.concat(seeds_offset, soff);
	seeds_color = Array.concat(seeds_color, scol);
}

//use seed[node] to get the Y values from the simi data in the arrays above

//Plot the tree from the x,y values
ilength = seeds.length*640;//scale the image to the number of seeds

newImage(na+"_Lineage_Tree", "RGB white", ilength, 1200, 1);

run("Line Width...", "line=4");

setFont("SansSerif" , 8, "antialiased");

if (isOpen("ROI Manager")) {
	selectWindow("ROI Manager");
	run("Close");
}

roiManager("UseNames", "true");

for (j=0; j<seeds.length; j++) {

//draw seed branch first
		
		col = seeds_color[j];
		run("Colors...", "foreground=&col background=black selection=&col");
		seed = seeds[j];
		offset = seeds_offset[j];

		//seedlength is the length of the seed cell
		for (f=0; f<cell_name.length; f++) {
		
			if (seed == cell_name[f]) {

				seedlength = length[f];}

		}
		drawLine(315+offset, 0, 315+offset, seedlength*15);
		makeLine(315+offset, 0, 315+offset, seedlength*15);
		Roi.setName(seed); 
		roiManager("Add");
		Overlay.drawString(seed, 315+offset-15, 15);
		Overlay.show(); 
		
		node_dis = newArray();
			
		//get the distance of each node from the start by summming the lengths of its subnodes
		for (h=0; h<nodes.length; h++){
			node = nodes[h];
			
			node1 = seed+node;

		    exists = occurencesInArray(cell_name,node1);
			if (exists == 1) {
		    
		    dis = 0;
			for (i=0; i<lengthOf(node); i++) {		
				
				node2index = lengthOf(node)-i;
				node2 = seed+substring(node, 0, node2index);

				for (b=0; b<cell_name.length; b++) {
					if (node2 == cell_name[b]) {
						dis = dis + length[b];
	
					}			
				}
			}
		}
 				else{dis = 0;}

			node_dis = Array.concat(node_dis, dis);
		}
		
	    run("Colors...", "foreground=&col background=black selection=&col");
	    
	    
//loop through the nodes and construct the tree
	for (g=0; g<nodes.length; g++){

		if (node_dis[g] == 0) {} else {
			seed = seeds[j];
			node3 = nodes[g];
			node4 = seed+node3;
			nx = x_index[g];		
			ndis = node_dis[g];
		
			//get previous node length in loop
			teststring = substring(node3, 0, (lengthOf(node3)-1));

			node5 = seed+teststring;
			if (lengthOf(teststring) > 1) {	

				for (v=0; v<nodes.length; v++) {
					 if (teststring == nodes[v]) {
					ndis2 = node_dis[v];
					} 
				}
			}	
					else { //If node3 is ABa ABp it can't find the length in the node lengths -> go back to lengths
						for (m=0; m<cell_name.length; m++) {
							if (node5 == cell_name[m]) {

							ndis2 = length[m];
							}
			
						}
					}

		
					
			//text offset left or right depending on whether this is a right or left cells
			texttest = substring(node3, lengthOf(node3)-1, lengthOf(node3));
			textoffset = 0;

			if (texttest == left) {textoffset = "-25";} else {textoffset = "0";}

			drawLine(nx+offset, (ndis)*15, nx+offset, ndis2*15);
			makeLine(nx+offset, (ndis)*15, nx+offset, ndis2*15);
			Roi.setName(node4); 
			roiManager("Add");	
			Overlay.drawString(node4, nx+offset+textoffset, ndis2*15);
			Overlay.show(); 
			
			xdis=10;
		    nodelevel = lengthOf(node3);
			
			if (texttest == left) {

				for (z=0; z<level_index.length; z++) {
					if (nodelevel == level_index[z]) {
						xdis = level_distance[z];

					}
				}
			drawLine(nx+offset, ndis2*15, nx+offset+xdis, ndis2*15);
			makeLine(nx+offset, ndis2*15, nx+offset+xdis, ndis2*15);
			Roi.setName("X_"+node4); 
			roiManager("Add");

						
		
					}
			}
	}
}

//flag cell if it is a seed

is_seed = newArray();
//iss = "FALSE";

for (i=0; i<cell_name.length; i++) {

	iss="FALSE";
	for (j=0; j<seeds.length; j++){
		
		if (cell_name[i] == seeds[j]) {
			iss = "TRUE";
			} else {}
	
		}
		is_seed = Array.concat(is_seed, iss);
	}


//flag cell if the final cell in a lineage
cell_flag = newArray();

for (i=0; i<cell_name.length; i++) {
	
	cnam = cell_name[i];
	flag = "Flag";

	for (j=0; j<cell_name.length; j++) {
	
		if ((cnam+left == cell_name[j])||(cnam+right == cell_name[j])) {
			flag = "";
			} 
		}
	if (is_seed[i]=="True") {flag = "Flag";}
	cell_flag = Array.concat(cell_flag, flag);
}

run("Colors...", "foreground=&col background=black selection=black");
roiManager("Show All");

//get the level of each cell - this is compicated because I can't predict the length of the seed name 
cell_levels = newArray();
clev = 0;

for (i=0; i<cell_name.length; i++) {
	
	cn = cell_name[i];
	
	for (j=0; j<seeds.length; j++) {
		sn = seeds[j];
		
		for (k=0; k<nodes.length; k++) {
			nn = nodes[k];
			
			if (cn == sn+nn) {
				clev = node_levels[k];
		}
	  }
	}
cell_levels = Array.concat(cell_levels, clev);	
}


//get cell cycle times
cell_tc = newArray();
for (i=0; i<cell_name.length; i++) {
	tc = (length[i])*t_mins;
	cell_tc = Array.concat(cell_tc, tc);
}

//print results to summary table
for (i=0; i<cell_name.length; i++) {

print(ptab,embryo[i]+"\t"+cell_name[i]+"\t"+cell_levels[i]+"\t"+cell_tc[i]+"\t"+is_seed[i]+"\t"+cell_flag[i]);

}




}

}

}


//Returns the number of times the value occurs within the array///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function occurencesInArray(array, value) {
    count=0;
    for (a=0; a<lengthOf(array); a++) {
        if (array[a]==value) {
            count++;
        }
    }
    return count;
}