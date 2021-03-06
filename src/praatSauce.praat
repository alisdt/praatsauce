###############
# PraatSauce
###############

# Copyright (c) 2018-2019 James Kirby

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


# Portions of PraatSauce are based on

# spectralTiltMaster.praat
# version 0.0.5
# copyright 2009-2010 Timothy Mills
# <mills.timothy@gmail.com>

# VoiceSauce
# version 1.31
# http://www.seas.ucla.edu/spapl/voicesauce/

###############################
## includes
###############################
include splitstring.praat
include log_output.praat
include praatSauceEngine.praat

###
### The opening form gets information on the location of the files to process,
### where the output should go, the structure of the TextGrids, which labels
### to process, and the temporal resolution of the measurements.
###

clearinfo

form Directory and measures
    comment Input directory and results file
    sentence inputdir /Users/jkirby/Projects/praatsauce/comp/madurese/
    sentence textgriddir /Users/jkirby/Projects/praatsauce/comp/madurese/
    sentence outputdir /Users/jkirby/Projects/praatsauce/comp/
    sentence outputfile spectral_measures.txt
    comment If measuring in sessions, use this parameter to pick up where you left off:
    natural startToken 1
    comment Which is your interval tier?
    natural interval_tier 1
    comment Enter interval labels you don't want to process as a well-formed regex:
    sentence skip_these_labels ^$|^\s+$|r
    comment Which is your point tier? (Enter 0 if you aren't using a point tier)
    integer point_tier 0
    comment If using a point tier: enter the labels of interest, separated by spaces:
    sentence point_tier_labels ov cv rv
    comment What character separates linguistic variables in token names? (e.g. "-" or "_")
    sentence separator _
    #comment Some measures (formant measure, pitch tracking, h1-a3, a1-a2)
    #comment allow you to manually check the output.
    comment What portion of tokens do you wish to (randomly) manually inspect?
    comment (0=none, 0.5 half, 1=all, etc.)
    real manualCheckFrequency 0
    comment At what points in the segment should we record measurements?
    optionmenu Measure: 2
       option n equidistant points
       option every n milliseconds
    comment If n equidistant points, how many? (e.g. 1, 3, 11...)
    comment If every n milliseconds, at what msec interval? (e.g. 5, 10...)
    natural Points 5
endform

###
### The second form lets the user select which measures to run, and
### obtains some general analysis parameters that are used by the
### subscripts.
###
beginPause: "Select measurements"
    comment: "Resample to 16 KHZ?"
    boolean: "resample_to_16k", 1
    comment: "Spectral measure(s) to take"
    boolean: "pitchTracking", 1
    boolean: "formantMeasures", 1
    boolean: "spectralMeasures", 1
    comment: "Note that taking spectral measures requires both formant and pitch analysis;"
    comment: "checking this box implies checking the two previous boxes."
	comment: "You can elect to load existing Pitch and Formant objects in a moment."
    comment: "Analysis window properties"
    positive: "windowLength", 0.025
    positive: "windowPosition", 0.5
    positive: "maxFormantHz", 5000
    comment: "For scripts that display spectrograms, what window size?"
    positive: "spectrogramWindow", 0.005
    #comment: "Smoothing window size (set to 0 for no smoothing)"
    #integer: "smoothWindowSize", 20
    #comment: "Select a smoothing algorithm"
    #optionMenu: "smoother", 1
    #option: "Simple moving average"
    #option: "Weighted symmetric moving average"
endPause: "Continue", 1

@show_common_settings:
... resample_to_16k, windowLength, windowPosition, maxFormantHz

###
### The following form obtains parameters specific to the spectral
### measurement subscript. This form will be shown only if the
### user has selected spectral measures in the previous window.
### Not currently implemented. However, if spectralMeasures is
### selected, automatically select pitch and formant tracking,
### since these objects are both needed to calculate the spectral
### balance measures.
###

if spectralMeasures
#    beginPause ("VoiceSauce-like Spectral magnitude measurement options")
#        comment ("Do you want to save the display summary of each token's")
#        comment ("analysis as an EPS file?")
#        boolean ("spectralMagnitudeSaveAsEPS", 0)
#        comment ("Maximum frequency for LTAS display")
#        positive ("maxDisplayHz", 5000)
#    endPause ("Continue", 1)
#
#    #printline -------
#    #printline Spectral Magnitude
#    #printline -------
#    #printline smoothingHz: <'smoothingHz'>
#    #printline
	pitchTracking = 1
	formantMeasures = 1
endif

###
### The following form obtains parameters specific to the pitch
### measurement subscript. This form will be shown only if the
### user has selected pitch tracking in the previous window.
###

if pitchTracking
    beginPause ("Pitch tracking options")
    comment: "Do you want to load existing Pitch objects, or generate new ones?"
    boolean: "useExistingPitch", 0
    comment ("Lower and upper limits to estimated frequency?")
    positive ("f0min", 50)
    positive ("f0max", 300)

    endPause ("Continue", 1)
    @show_pitch_tracking: useExistingPitch, f0min, f0max
endif

###
### The following form obtains parameters specific to the formant
### measurement subscript. This form will be shown only if the
### user has selected formant tracking in the previous window.
###

if formantMeasures
    beginPause: "Formant measurement options"
        comment: "Would you like to listen to each sound if checking tracks?"
        boolean: "listenToSound", 0
        comment: "Time step determines how close the analysis frames are for"
        comment: "formant measurement.  Set at 0 for default (1/4 of window)."
        real: "timeStep", 0
        comment: "The maximum number of formants and the point of pre-emphasis"
        comment: "are key parameters in the Burg formant estimation algorithm."
        integer: "maxNumFormants", 5
        positive: "preEmphFrom", 50
        comment: "Would you like to smooth the formant tracks?"
        boolean: "formantTracking", 1
        comment: "If yes: the tracking used to smooth formant contours after initial"
        comment: "estimates requires reference formant values (neutral vowel)."
        positive: "F1ref", 500
        positive: "F2ref", 1500
        positive: "F3ref", 2500
        comment: "Do you want to save the visual output as an EPS file?"
        boolean: "saveAsEPS", 0
        comment: "Do you want to load existing Formant objects, or generate new ones?"
        boolean: "useExistingFormants", 0
        comment: "Do you want to use Praat's estimates of formant bandwidths, or"
        comment: "bandwidths estimated by the Hawks and Miller formula?"
        comment: "Note: this requires that you selected to run a pitch analysis previously"
        boolean: "useBandwidthFormula", 0
    endPause: "Continue", 1

    @show_formant_measures:
    ... listenToSound, timeStep, maxNumFormants, preEmphFrom, formantTracking,
    ... f1ref, f2ref, f3ref, saveAsEPS, useExistingFormants, useBandwidthFormula
endif

###
## A quick pause so that the user can check all of the parameters
## reported in the info window, and save them to a file if needed.
###

beginPause ("Got all that?")
    comment ("If you want to save this list of parameters to a file,")
    comment ("select the Info window and choose 'Save As...' from ")
    comment ("the File menu.")
endPause ("Continue", 1)

# do the rest of the processing (common between praatSauce and shellSauce)
@praatSauceEngine
