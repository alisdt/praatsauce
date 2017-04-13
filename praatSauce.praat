###############
# praatSauce
# version 0.0.1
###############

# based on code from

# spectralTiltMaster.praat
# version 0.0.5
# copyright 2009-2010 Timothy Mills
# <mills.timothy@gmail.com>
#
# VoiceSauce 
# version 1.27
# http://www.seas.ucla.edu/spapl/voicesauce/
#
# These scripts are released under the GNU General Public License version 3.0 
# The included file "gpl-3.0.txt" or the URL "http://www.gnu.org/licenses/gpl.html" 
# contains the full text of the license.

###
### The opening form gets information from the user on where the data is,
### where the output should go, and on the structure of the label files
### (TextGrids).
###

## string splitting function
include splitstring.praat

form Directory and measures
 comment Input directory and results file
 sentence inputdir /Users/jkirby/Desktop/demo/
 sentence outputfile /Users/jkirby/Desktop/demo/
 comment If measuring in sessions, use this parameter to pick up where you left off.
 integer startToken 1
 comment Which interval do you want to analyse?
 natural tier 4
 sentence interval_label v
 integer interval_number 0
 comment When parsing token names for linguistic variables, what separator
 comment character should I look for? (ie, "-" or "_")
 sentence separator _
 #comment Some measures (formant measure, pitch tracking, h1-a3, a1-a2) 
 #comment allow you to manually check the output.
 comment What portion of tokens do you wish to (randomly) manually inspect? 
 comment (e.g.0=none, 0.5 half, 1=all)
 real manualCheckFrequency 0
 comment At what points in the segment should we record measurements?
 optionmenu Measure: 1
    option n equidistant points
    option every n milliseconds
 comment If n equidistant points, how many? (e.g. 1, 3, 11...)
 comment If every n milliseconds, at what ms interval? (e.g. 5, 10...)
 natural Points 3 
 comment If every n milliseconds, at how many ms to stop measuring? (e.g. 100)
 natural absLimit 100
endform

###
### The second form lets the user select which measures to run, and 
### obtains some general analysis parameters that are used by most 
### of the subscripts.
###
beginPause ("Select measurements")
    comment ("Spectral measure(s) to take")
    boolean ("formantMeasures", 1)
    boolean ("pitchTracking", 1)
    boolean ("voicesauceMeasures", 0)
    comment ("Note that VoiceSauce measures requires either an existing Formant object, or")
    comment ("selecting formantMeasures above.")
    comment ("Analysis window properties")
    positive ("windowLength", 0.025)
    positive ("windowPosition", 0.5)
    positive ("maxAnalysisHz", 5000)
    comment ("For scripts that display spectrograms, what window size?")
    positive ("spectrogramWindow", 0.005)
endPause ("Continue", 1)

clearinfo

###
### Each of the following forms obtains parameters specific to one
### of the subscripts.  Forms will be shown only for measures the 
### user has selected.  For each one, the selected parameters are 
### displayed in the info screen for the user to verify before 
### beginning the analysis.
###

if formantMeasures
    beginPause ("Formant measurement options")
        comment ("Would you like to listen to each sound when checking tracks?")
        boolean ("listenToSound", 0)
        comment ("Time step determines how close the analysis frames are for")
        comment ("formant measurement.  Set at 0 for default (1/4 of window).")
        real ("timeStep", 0)
        comment ("The maximum number of formants and the point of pre-emphasis")
        comment ("are key parameters in the Burg formant estimation algorithm.")
        integer ("maxNumFormants", 5)
        positive ("preEmphFrom", 50)
        #comment ("The tracking used to smooth formant contours after initial")
        #comment ("estimates requires reference formant values (neutral vowel).")
        #positive ("F1ref", 500)
        #positive ("F2ref", 1500)
        #positive ("F3ref", 2500)
        comment ("Do you want to save the visual output as an EPS file?")
        boolean ("saveAsEPS", 0)
        comment ("Do you want to use exisiting formant files and just re-measure from them?")
        boolean ("useExistingFormants", 1)
    endPause ("Continue", 1)
    
    printline -------
    printline Formant measures
    printline -------
    printline listenToSound:  <'listenToSound'>
    printline timeStep:  <'timeStep'>
    printline maxNumFormants:  <'maxNumFormants'>
    printline preEmphFrom:  <'preEmphFrom'>
    printline saveAsEPS:  <'saveAsEPS'>
    printline useExistingFormants: <'useExistingFormants'>
    printline
endif

if pitchTracking
    beginPause ("Pitch tracking options")
    comment ("Lower and upper limits to estimated frequency?")
    positive ("f0min", 50)
    positive ("f0max", 500)
    endPause ("Continue", 1)
    
    printline -------
    printline Pitch tracking
    printline -------
    printline f0min:  <'f0min'>
    printline f0max:  <'f0max'>
    printline
endif

if voicesauceMeasures
    beginPause ("VoiceSauce-like Spectral magnitude measurement options")
        comment ("Do you want to save the display summary of each token's")
        comment ("analysis as an EPS file?")
        boolean ("spectralMagnitudeSaveAsEPS", 0)
        comment ("Maximum frequency for LTAS display")
        positive ("maxDisplayHz", 5000)
    endPause ("Continue", 1)
    
    printline -------
    printline Spectral Magnitude
    printline -------
    printline smoothingHz: <'smoothingHz'>
    printline
endif

##
# A quick pause so that the user can check all of the parameters 
# reported in the info window, and save them to a file if needed.
#
beginPause ("Got all that?")
    comment ("If you want to save this list of parameters to a file,")
    comment ("select the Info window and choose 'Save As...' from ")
    comment ("the File menu.")
endPause ("Continue", 1)
#
##

## If outputfile already exists, delete it (so that it can be 
## replaced with a new version).  Also, clear info screen.
outputfile$ = "'outputfile$'spectral_measures.txt"
filedelete 'outputfile$'
clearinfo

## Get directory listing, sort, count
Create Strings as file list... fileList 'inputdir$'*.TextGrid
stringsListID = selected("Strings", 1)
Sort
numTokens = Get number of strings

##
# Build up header variable based on user's choices in the form.
header$ = "filename"

# Add label for each linguistic variable parsed from token names.
# In order to be as flexible as possible, this script simply labels
# these variables 'var1', 'var2', etc.  After measurement, you can 
# change these labels in the text file or in their statistical 
# software to better reflect the data.  Alternatively, you can 
# modify this section of the script.

select stringsListID
sampleFileName$ = Get string... 1
@splitstring: sampleFileName$, separator$
for i from 1 to splitstring.strLen
    header$ = "'header$',var'i'"
endfor

## Add interval label column
header$ = "'header$','interval_label$'"

## Add header columns for point number and the absolute timepoint value
header$ = "'header$',t,ms"

## Add header columns for selected measures
if formantMeasures
 header$ = "'header$',F1,F2,F3"
endif
if pitchTracking
 header$ = "'header$',f0"
endif
if voicesauceMeasures
 header$ = "'header$',H1,H2,H4,A1,A2,A3,H1adj,H2adj,H4adj,A1adj,A2adj,A3adj,H2k,H5k,CPP,CPPS,HNR,HNR05,HNR15,HNR25"
endif
header$ = "'header$''newline$'"

## Put header in outputfile and on Info screen.
fileappend 'outputfile$' 'header$'
echo 'header$'
## (end building of header)

###
# The following 'for' loop does the bulk of the processing.  Each cycle of
# the loop processes a single token.
#
for currentToken from startToken to numTokens

    # Retrieve filename of current token
    select stringsListID
    currentTextGridFile$ = Get string... 'currentToken'
    basename$ = left$("'currentTextGridFile$'", index("'currentTextGridFile$'", ".") - 1)
    
    # Load Sound and TextGrid
    Read from file... 'inputdir$''currentTextGridFile$'
    textGridID = selected("TextGrid")
    # get the label of the interval if interval_number is > 0
    if interval_number > 0
        interval_label$ = Get label of interval... 'tier' 'interval_number'
    endif
    
    Read from file... 'inputdir$''basename$'.wav
    ## Note that Sound is not resampled b/c later we use To Formant (burg)... 
    ## which resamples to twice the frequency of maxFormant (so 10k-11k usually)
    soundID = selected("Sound")
    
    # If there is an existing formant-tracking parameter file 
    # ("*.FmtParam.txt"), load it and use its parameters rather
    # than the ones entered in the opening forms.
    formantParamFile$ = "'inputdir$''basename$'.FmtParam.txt"
    
    if fileReadable (formantParamFile$)
        #pause Found <'formantParamFile$'>, started loop
        formantParameters$ < 'formantParamFile$'
        # This should contain a tab-delimited list in the following order:
        # windowPosition, windowLength, maxNumFormants, maxFormantHz, preEmphFrom, spectrogramWindow
        #echo 'formantParameters$'
        
        parameterIndex = index(formantParameters$, ,) - 1
        parameter$ = left$(formantParameters$, parameterIndex)
        windowPosition = 'parameter$'
        #printline windowPosition    = <'windowPosition'>
        formantParameters$ = mid$(formantParameters$, parameterIndex+2, 10000)
        parameterIndex = index(formantParameters$, ,) - 1
        parameter$ = left$(formantParameters$, parameterIndex)
        windowLength = 'parameter$'
        #printline windowLength      = <'windowLength'>
        formantParameters$ = mid$(formantParameters$, parameterIndex+2, 10000)
        parameterIndex = index(formantParameters$, ,) - 1
        parameter$ = left$(formantParameters$, parameterIndex)
        maxNumFormants = 'parameter$'
        #printline maxNumFormants    = <'maxNumFormants'>
        formantParameters$ = mid$(formantParameters$, parameterIndex+2, 10000)
        parameterIndex = index(formantParameters$, ,) - 1
        parameter$ = left$(formantParameters$, parameterIndex)
        maxFormantHz = 'parameter$'
        #printline maxFormantHz      = <'maxFormantHz'>
        formantParameters$ = mid$(formantParameters$, parameterIndex+2, 10000)
        parameterIndex = index(formantParameters$, ,) - 1
        parameter$ = left$(formantParameters$, parameterIndex)
        preEmphFrom = 'parameter$'
        #printline preEmphFrom       = <'preEmphFrom'>
        formantParameters$ = mid$(formantParameters$, parameterIndex+2, 10000)
        spectrogramWindow = 'formantParameters$'
        #printline spectrogramWindow = <'spectrogramWindow'>
     # else: Didn't find parameter file; use defaults.
    endif
    
    ## Parse the token name into a series of linguistic variables.
    lingVars$ = ""
    @splitstring: basename$, separator$
    for i from 1 to splitstring.strLen
       lingVars$ = lingVars$ + splitstring.array$[i] + ","
    endfor
    
    ## Determine how many timepoints we're measuring at
    if measure = 1
       timepoints = points
    elsif measure = 2
       timepoints = absLimit/points
    endif
    
    ## Now: write a line for each point (since our matrices will have this many rows in them).
    
    # Report current token number, name, and lingVars$:
    echo <'currentToken' of 'numTokens'> 'basename$':  'lingVars$'
    
    ## Manually check this token at random? 
    randomNumber = randomUniform(0,1)
    if manualCheckFrequency > randomNumber
        manualCheck = 1
    else
       manualCheck = 0
    endif 
   
    ### 
    ### Formant measures
    ### 
    if formantMeasures
        select 'soundID'
        plus 'textGridID'
        execute formantMeasures-notracking.praat 'tier' 'interval_number' 'interval_label$' 'windowPosition' 'windowLength' 1 'manualCheck' 'saveAsEPS' 'useExistingFormants' 'inputdir$' 'basename$' 'listenToSound' 'timeStep' 'maxNumFormants' 'maxAnalysisHz' 'preEmphFrom' 'spectrogramWindow' 'measure' 'timepoints' 'absLimit'
       	select Matrix FormantAverages
       	formantResultsID = selected("Matrix")
    
    endif
    ### (end of formant measures)
    
    ###
    ### Pitch tracking
    ###
    if pitchTracking
        if (fileReadable ("'inputdir$''basename$'.Pitch"))
            Read from file... 'inputdir$''basename$'.Pitch
        else
            select 'soundID'
            To Pitch... 0 'f0min' 'f0max'
        endif
        pitchID = selected("Pitch")
        plus soundID
        plus textGridID
        execute pitchTracking.praat 'tier' 'interval_number' 'interval_label$' 'windowPosition' 'windowLength' 'manualCheck' 1 'measure' 'timepoints' 'absLimit'
       
        ### Save output Matrix
        select Matrix PitchAverages
        pitchResultsID = selected("Matrix")
        select 'pitchID'
        Write to text file... 'inputdir$''basename$'.Pitch
    endif
    ### (end of pitch tracking)
    
    ### 
    ### VoiceSauce-based Spectral corrections (including H1*, H2*, H4, A1*, A2*, A3* from Iseli et al.)
    ###
    if voicesauceMeasures
        # Load Formant object from disk.  If not possible, quit with error message
        if fileReadable ("'inputdir$''basename$'.Formant")
            Read from file... 'inputdir$''basename$'.Formant
            formantID = selected("Formant")
        else
            exit Cannot load formant data file <'name$'.Formant>.
        endif
    
        if (fileReadable ("'inputdir$''basename$'.Pitch"))
            Read from file... 'inputdir$''basename$'.Pitch
        else
            select 'soundID'
            To Pitch... 0 'f0min' 'f0max'
        endif
        pitchID = selected("Pitch")
        select 'soundID'
        plus 'textGridID'
        plus 'formantID'
        plus 'pitchID'
        execute voicesauceMeasures.praat 'tier' 'interval_number' 'interval_label$' 'windowPosition' 'windowLength' 1 'spectralMagnitudeSaveAsEPS' 'inputdir$' 'manualCheck' 'maxDisplayHz' 'measure' 'timepoints' 'absLimit' 'f0min' 'f0max'
    
        ## Assign ID to output matrix
        select Matrix IseliMeasures
        iseliResultsID = selected("Matrix")
    
    endif 
    ### (end of spectralMagnitude measure)
    
    # Report results
    #echo <token 'currentToken' of 'numTokens'> 'results$'
    
    ## Here we:
    ##  1. look for results matrices
    ##  2. Write as many line as the matrices have rows
    
    for t from 1 to timepoints
    	# Begin building results string with file and linguistic info.
    	results$ = "'basename$','interval_label$','lingVars$''t'"
        # have we already written the ms time or do we still need to write it?
        msflag = 0
 
        if formantMeasures 
            select 'formantResultsID'
            mspoint = Get value in cell... t 1
			msflag = 1
       		results$ = "'results$','mspoint'"
     		for formant from 2 to 4
       		    currentFormant = Get value in cell... t 'formant'
       		    results$ = "'results$','currentFormant'"
     		endfor
        endif			
    
        if pitchTracking
            select 'pitchResultsID'
            if msflag = 0
                mspoint = Get value in cell... t 1
       		    results$ = "'results$','mspoint'"
                msflag = 1
            endif
       	    currentPitch = Get value in cell... t 2 
       		results$ = "'results$','currentPitch'"
        endif
    
        if voicesauceMeasures
            select 'iseliResultsID'
            if msflag = 0
                mspoint = Get value in cell... t 1
       		    results$ = "'results$','mspoint'"
            endif
       	    for measurement from 2 to 21
       		    aMeasure = Get value in cell... t 'measurement'
       		    results$ = "'results$','aMeasure'"
       	    endfor	
        endif
    
        ## FINALLY write the thing out....for this timepoint
        fileappend 'outputfile$' 'results$''newline$'
    endfor	
    
    select all
    minus Strings fileList
    Remove
    
endfor
## (End main analysis loop, which cycles through all tokens)

select 'stringsListID'
Remove

echo Analysis complete: <'numTokens'> tokens measured.
print All files processed -- that was funtastic!
