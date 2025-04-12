BEGIN {
    ON  = 1
    OFF = 0
    PROTEIN_ATOMTYPES = "CNOSHXM" # default protein
    # PROTEIN_ATOMTYPES = "CNOSHZL" # protein with Zn and Ca
    # PROTEIN_ATOMTYPES should be set to the same string
    # as ATOMTYPE is in autogrid.h; make sure this
    # is a copy of its value there.
    # ALL_TYPES = "CANOSPH"
    ALL_TYPES = "CANOSPHfFcbIMZLX"
    NUM_TYPES = length(ALL_TYPES)
    for (i=1; i <= NUM_TYPES; i++) {
      n[substr(ALL_TYPES, i,1)] = 0
    }

    #
    # Free energy model 140n s coefficients:
    #
    FE_vdW_coeff   = 0.1485
    FE_estat_coeff = 0.1146
    FE_hbond_coeff = 0.0656
    FE_tors_coeff  = 0.3113
    FE_desol_coeff = 0.1711

    # AutoDock Binding Free Energy Model 140n
    # Uses the C.A.Lig.only solvation model, i.e.
    # aliphatic (C) and aromatic (A) carbon atoms only
    #
    SolVol[ "C" ] = 12.77
    SolVol[ "A" ] = 10.80
    SolVol[ "N" ] =  0.
    SolVol[ "O" ] =  0.
    SolVol[ "H" ] =  0.

    #SolPar[ "C" ] =  0.6844
    #SolPar[ "A" ] =  0.1027

    SolPar[ "C" ] =  4.0 * FE_desol_coeff
    SolPar[ "A" ] =  0.6 * FE_desol_coeff
    SolPar[ "N" ] =  0.
    SolPar[ "O" ] =  0.
    SolPar[ "H" ] =  0.

    SolCon[ "C" ] =  0.
    SolCon[ "A" ] =  0.
    SolCon[ "N" ] =  0.
    SolCon[ "O" ] =  0.236
    SolCon[ "H" ] =  0.118


    Rij[ "lj" "C" "C" ] = 4.00  # C-C
    Rij[ "lj" "C" "N" ] = 3.75  # C-N
    Rij[ "lj" "N" "C" ] = 3.75  # N-C
    Rij[ "lj" "C" "O" ] = 3.60  # C-O
    Rij[ "lj" "O" "C" ] = 3.60  # O-C
    Rij[ "lj" "C" "P" ] = 4.10  # C-P
    Rij[ "lj" "P" "C" ] = 4.10  # P-C
    Rij[ "lj" "C" "S" ] = 4.00  # C-S
    Rij[ "lj" "S" "C" ] = 4.00  # S-C
    Rij[ "lj" "C" "H" ] = 3.00  # C-H
    Rij[ "lj" "H" "C" ] = 3.00  # H-C
    Rij[ "lj" "C" "f" ] = 2.65  # C-Fe
    Rij[ "lj" "f" "C" ] = 2.65  # Fe-C
    Rij[ "lj" "C" "F" ] = 3.54  # C-F
    Rij[ "lj" "F" "C" ] = 3.54  # F-C
    Rij[ "lj" "C" "c" ] = 4.04  # C-Cl
    Rij[ "lj" "c" "C" ] = 4.04  # Cl-C
    Rij[ "lj" "C" "b" ] = 4.17  # C-Br
    Rij[ "lj" "b" "C" ] = 4.17  # Br-C
    Rij[ "lj" "C" "I" ] = 4.36  # C-I
    Rij[ "lj" "I" "C" ] = 4.36  # I-C
    Rij[ "lj" "C" "M" ] = 2.65  # C-Mg
    Rij[ "lj" "M" "C" ] = 2.65  # Mg-C
    Rij[ "lj" "C" "Z" ] = 2.74  # C-Zn
    Rij[ "lj" "Z" "C" ] = 2.74  # Zn-C
    Rij[ "lj" "C" "L" ] = 2.99  # C-Ca
    Rij[ "lj" "L" "C" ] = 2.99  # Ca-C
    Rij[ "lj" "C" "X" ] = 3.00  # C-Xx
    Rij[ "lj" "X" "C" ] = 3.00  # Xx-C

    Rij[ "lj" "N" "C" ] = 3.75  # N-C
    Rij[ "lj" "C" "N" ] = 3.75  # C-N
    Rij[ "lj" "N" "N" ] = 3.50  # N-N
    Rij[ "lj" "N" "O" ] = 3.35  # N-O
    Rij[ "lj" "O" "N" ] = 3.35  # O-N
    Rij[ "lj" "N" "P" ] = 3.85  # N-P
    Rij[ "lj" "P" "N" ] = 3.85  # P-N
    Rij[ "lj" "N" "S" ] = 3.75  # N-S
    Rij[ "lj" "S" "N" ] = 3.75  # S-N
    Rij[ "lj" "N" "H" ] = 2.75  # N-H
    Rij[ "lj" "H" "N" ] = 2.75  # H-N
    Rij[ "lj" "N" "f" ] = 2.40  # N-Fe
    Rij[ "lj" "f" "N" ] = 2.40  # Fe-N
    Rij[ "lj" "N" "F" ] = 3.29  # N-F
    Rij[ "lj" "F" "N" ] = 3.29  # F-N
    Rij[ "lj" "N" "c" ] = 3.79  # N-Cl
    Rij[ "lj" "c" "N" ] = 3.79  # Cl-N
    Rij[ "lj" "N" "b" ] = 3.92  # N-Br
    Rij[ "lj" "b" "N" ] = 3.92  # Br-N
    Rij[ "lj" "N" "I" ] = 4.11  # N-I
    Rij[ "lj" "I" "N" ] = 4.11  # I-N
    Rij[ "lj" "N" "M" ] = 2.40  # N-Mg
    Rij[ "lj" "M" "N" ] = 2.40  # Mg-N
    Rij[ "lj" "N" "Z" ] = 2.49  # N-Zn
    Rij[ "lj" "Z" "N" ] = 2.49  # Zn-N
    Rij[ "lj" "N" "L" ] = 2.74  # N-Ca
    Rij[ "lj" "L" "N" ] = 2.74  # Ca-N
    Rij[ "lj" "N" "X" ] = 2.75  # N-Xx
    Rij[ "lj" "X" "N" ] = 2.75  # Xx-N

    Rij[ "lj" "O" "C" ] = 3.60  # O-C
    Rij[ "lj" "C" "O" ] = 3.60  # C-O
    Rij[ "lj" "O" "N" ] = 3.35  # O-N
    Rij[ "lj" "N" "O" ] = 3.35  # N-O
    Rij[ "lj" "O" "O" ] = 3.20  # O-O
    Rij[ "lj" "O" "P" ] = 3.70  # O-P
    Rij[ "lj" "P" "O" ] = 3.70  # P-O
    Rij[ "lj" "O" "S" ] = 3.60  # O-S
    Rij[ "lj" "S" "O" ] = 3.60  # S-O
    Rij[ "lj" "O" "H" ] = 2.60  # O-H
    Rij[ "lj" "H" "O" ] = 2.60  # H-O
    Rij[ "lj" "O" "f" ] = 2.25  # O-Fe
    Rij[ "lj" "f" "O" ] = 2.25  # Fe-O
    Rij[ "lj" "O" "F" ] = 3.15  # O-F
    Rij[ "lj" "F" "O" ] = 3.15  # F-O
    Rij[ "lj" "O" "c" ] = 3.65  # O-Cl
    Rij[ "lj" "c" "O" ] = 3.65  # Cl-O
    Rij[ "lj" "O" "b" ] = 3.77  # O-Br
    Rij[ "lj" "b" "O" ] = 3.77  # Br-O
    Rij[ "lj" "O" "I" ] = 3.96  # O-I
    Rij[ "lj" "I" "O" ] = 3.96  # I-O
    Rij[ "lj" "O" "M" ] = 2.25  # O-Mg
    Rij[ "lj" "M" "O" ] = 2.25  # Mg-O
    Rij[ "lj" "O" "Z" ] = 2.34  # O-Zn
    Rij[ "lj" "Z" "O" ] = 2.34  # Zn-O
    Rij[ "lj" "O" "L" ] = 2.59  # O-Ca
    Rij[ "lj" "L" "O" ] = 2.59  # Ca-O
    Rij[ "lj" "O" "X" ] = 2.60  # O-Xx
    Rij[ "lj" "X" "O" ] = 2.60  # Xx-O

    Rij[ "lj" "P" "C" ] = 4.10  # P-C
    Rij[ "lj" "C" "P" ] = 4.10  # C-P
    Rij[ "lj" "P" "N" ] = 3.85  # P-N
    Rij[ "lj" "N" "P" ] = 3.85  # N-P
    Rij[ "lj" "P" "O" ] = 3.70  # P-O
    Rij[ "lj" "O" "P" ] = 3.70  # O-P
    Rij[ "lj" "P" "P" ] = 4.20  # P-P
    Rij[ "lj" "P" "S" ] = 4.10  # P-S
    Rij[ "lj" "S" "P" ] = 4.10  # S-P
    Rij[ "lj" "P" "H" ] = 3.10  # P-H
    Rij[ "lj" "H" "P" ] = 3.10  # H-P
    Rij[ "lj" "P" "f" ] = 2.75  # P-Fe
    Rij[ "lj" "f" "P" ] = 2.75  # Fe-P
    Rij[ "lj" "P" "F" ] = 3.65  # P-F
    Rij[ "lj" "F" "P" ] = 3.65  # F-P
    Rij[ "lj" "P" "c" ] = 4.14  # P-Cl
    Rij[ "lj" "c" "P" ] = 4.14  # Cl-P
    Rij[ "lj" "P" "b" ] = 4.27  # P-Br
    Rij[ "lj" "b" "P" ] = 4.27  # Br-P
    Rij[ "lj" "P" "I" ] = 4.46  # P-I
    Rij[ "lj" "I" "P" ] = 4.46  # I-P
    Rij[ "lj" "P" "M" ] = 2.75  # P-Mg
    Rij[ "lj" "M" "P" ] = 2.75  # Mg-P
    Rij[ "lj" "P" "Z" ] = 2.84  # P-Zn
    Rij[ "lj" "Z" "P" ] = 2.84  # Zn-P
    Rij[ "lj" "P" "L" ] = 3.09  # P-Ca
    Rij[ "lj" "L" "P" ] = 3.09  # Ca-P
    Rij[ "lj" "P" "X" ] = 3.10  # P-Xx
    Rij[ "lj" "X" "P" ] = 3.10  # Xx-P

    Rij[ "lj" "S" "C" ] = 4.00  # S-C
    Rij[ "lj" "C" "S" ] = 4.00  # C-S
    Rij[ "lj" "S" "N" ] = 3.75  # S-N
    Rij[ "lj" "N" "S" ] = 3.75  # N-S
    Rij[ "lj" "S" "O" ] = 3.60  # S-O
    Rij[ "lj" "O" "S" ] = 3.60  # O-S
    Rij[ "lj" "S" "P" ] = 4.10  # S-P
    Rij[ "lj" "P" "S" ] = 4.10  # P-S
    Rij[ "lj" "S" "S" ] = 4.00  # S-S
    Rij[ "lj" "S" "H" ] = 3.00  # S-H
    Rij[ "lj" "H" "S" ] = 3.00  # H-S
    Rij[ "lj" "S" "f" ] = 2.65  # S-Fe
    Rij[ "lj" "f" "S" ] = 2.65  # Fe-S
    Rij[ "lj" "S" "F" ] = 3.54  # S-F
    Rij[ "lj" "F" "S" ] = 3.54  # F-S
    Rij[ "lj" "S" "c" ] = 4.04  # S-Cl
    Rij[ "lj" "c" "S" ] = 4.04  # Cl-S
    Rij[ "lj" "S" "b" ] = 4.17  # S-Br
    Rij[ "lj" "b" "S" ] = 4.17  # Br-S
    Rij[ "lj" "S" "I" ] = 4.36  # S-I
    Rij[ "lj" "I" "S" ] = 4.36  # I-S
    Rij[ "lj" "S" "M" ] = 2.65  # S-Mg
    Rij[ "lj" "M" "S" ] = 2.65  # Mg-S
    Rij[ "lj" "S" "Z" ] = 2.74  # S-Zn
    Rij[ "lj" "Z" "S" ] = 2.74  # Zn-S
    Rij[ "lj" "S" "L" ] = 2.99  # S-Ca
    Rij[ "lj" "L" "S" ] = 2.99  # Ca-S
    Rij[ "lj" "S" "X" ] = 3.00  # S-Xx
    Rij[ "lj" "X" "S" ] = 3.00  # Xx-S

    Rij[ "lj" "H" "C" ] = 3.00  # H-C
    Rij[ "lj" "C" "H" ] = 3.00  # C-H
    Rij[ "lj" "H" "N" ] = 2.75  # H-N
    Rij[ "lj" "N" "H" ] = 2.75  # N-H
    Rij[ "lj" "H" "O" ] = 2.60  # H-O
    Rij[ "lj" "O" "H" ] = 2.60  # O-H
    Rij[ "lj" "H" "P" ] = 3.10  # H-P
    Rij[ "lj" "P" "H" ] = 3.10  # P-H
    Rij[ "lj" "H" "S" ] = 3.00  # H-S
    Rij[ "lj" "S" "H" ] = 3.00  # S-H
    Rij[ "lj" "H" "H" ] = 2.00  # H-H
    Rij[ "lj" "H" "f" ] = 1.65  # H-Fe
    Rij[ "lj" "f" "H" ] = 1.65  # Fe-H
    Rij[ "lj" "H" "F" ] = 2.54  # H-F
    Rij[ "lj" "F" "H" ] = 2.54  # F-H
    Rij[ "lj" "H" "c" ] = 3.04  # H-Cl
    Rij[ "lj" "c" "H" ] = 3.04  # Cl-H
    Rij[ "lj" "H" "b" ] = 3.17  # H-Br
    Rij[ "lj" "b" "H" ] = 3.17  # Br-H
    Rij[ "lj" "H" "I" ] = 3.36  # H-I
    Rij[ "lj" "I" "H" ] = 3.36  # I-H
    Rij[ "lj" "H" "M" ] = 1.65  # H-Mg
    Rij[ "lj" "M" "H" ] = 1.65  # Mg-H
    Rij[ "lj" "H" "Z" ] = 1.74  # H-Zn
    Rij[ "lj" "Z" "H" ] = 1.74  # Zn-H
    Rij[ "lj" "H" "L" ] = 1.99  # H-Ca
    Rij[ "lj" "L" "H" ] = 1.99  # Ca-H
    Rij[ "lj" "H" "X" ] = 2.00  # H-Xx
    Rij[ "lj" "X" "H" ] = 2.00  # Xx-H

    Rij[ "lj" "f" "C" ] = 2.65  # Fe-C
    Rij[ "lj" "C" "f" ] = 2.65  # C-Fe
    Rij[ "lj" "f" "N" ] = 2.40  # Fe-N
    Rij[ "lj" "N" "f" ] = 2.40  # N-Fe
    Rij[ "lj" "f" "O" ] = 2.25  # Fe-O
    Rij[ "lj" "O" "f" ] = 2.25  # O-Fe
    Rij[ "lj" "f" "P" ] = 2.75  # Fe-P
    Rij[ "lj" "P" "f" ] = 2.75  # P-Fe
    Rij[ "lj" "f" "S" ] = 2.65  # Fe-S
    Rij[ "lj" "S" "f" ] = 2.65  # S-Fe
    Rij[ "lj" "f" "H" ] = 1.65  # Fe-H
    Rij[ "lj" "H" "f" ] = 1.65  # H-Fe
    Rij[ "lj" "f" "f" ] = 1.30  # Fe-Fe
    Rij[ "lj" "f" "F" ] = 2.19  # Fe-F
    Rij[ "lj" "F" "f" ] = 2.19  # F-Fe
    Rij[ "lj" "f" "c" ] = 2.69  # Fe-Cl
    Rij[ "lj" "c" "f" ] = 2.69  # Cl-Fe
    Rij[ "lj" "f" "b" ] = 2.81  # Fe-Br
    Rij[ "lj" "b" "f" ] = 2.81  # Br-Fe
    Rij[ "lj" "f" "I" ] = 3.01  # Fe-I
    Rij[ "lj" "I" "f" ] = 3.01  # I-Fe
    Rij[ "lj" "f" "M" ] = 1.30  # Fe-Mg
    Rij[ "lj" "M" "f" ] = 1.30  # Mg-Fe
    Rij[ "lj" "f" "Z" ] = 1.39  # Fe-Zn
    Rij[ "lj" "Z" "f" ] = 1.39  # Zn-Fe
    Rij[ "lj" "f" "L" ] = 1.64  # Fe-Ca
    Rij[ "lj" "L" "f" ] = 1.64  # Ca-Fe
    Rij[ "lj" "f" "X" ] = 1.65  # Fe-Xx
    Rij[ "lj" "X" "f" ] = 1.65  # Xx-Fe

    Rij[ "lj" "F" "C" ] = 3.54  # F-C
    Rij[ "lj" "C" "F" ] = 3.54  # C-F
    Rij[ "lj" "F" "N" ] = 3.29  # F-N
    Rij[ "lj" "N" "F" ] = 3.29  # N-F
    Rij[ "lj" "F" "O" ] = 3.15  # F-O
    Rij[ "lj" "O" "F" ] = 3.15  # O-F
    Rij[ "lj" "F" "P" ] = 3.65  # F-P
    Rij[ "lj" "P" "F" ] = 3.65  # P-F
    Rij[ "lj" "F" "S" ] = 3.54  # F-S
    Rij[ "lj" "S" "F" ] = 3.54  # S-F
    Rij[ "lj" "F" "H" ] = 2.54  # F-H
    Rij[ "lj" "H" "F" ] = 2.54  # H-F
    Rij[ "lj" "F" "f" ] = 2.19  # F-Fe
    Rij[ "lj" "f" "F" ] = 2.19  # Fe-F
    Rij[ "lj" "F" "F" ] = 3.09  # F-F
    Rij[ "lj" "F" "c" ] = 3.59  # F-Cl
    Rij[ "lj" "c" "F" ] = 3.59  # Cl-F
    Rij[ "lj" "F" "b" ] = 3.71  # F-Br
    Rij[ "lj" "b" "F" ] = 3.71  # Br-F
    Rij[ "lj" "F" "I" ] = 3.90  # F-I
    Rij[ "lj" "I" "F" ] = 3.90  # I-F
    Rij[ "lj" "F" "M" ] = 2.19  # F-Mg
    Rij[ "lj" "M" "F" ] = 2.19  # Mg-F
    Rij[ "lj" "F" "Z" ] = 2.29  # F-Zn
    Rij[ "lj" "Z" "F" ] = 2.29  # Zn-F
    Rij[ "lj" "F" "L" ] = 2.54  # F-Ca
    Rij[ "lj" "L" "F" ] = 2.54  # Ca-F
    Rij[ "lj" "F" "X" ] = 2.54  # F-Xx
    Rij[ "lj" "X" "F" ] = 2.54  # Xx-F

    Rij[ "lj" "c" "C" ] = 4.04  # Cl-C
    Rij[ "lj" "C" "c" ] = 4.04  # C-Cl
    Rij[ "lj" "c" "N" ] = 3.79  # Cl-N
    Rij[ "lj" "N" "c" ] = 3.79  # N-Cl
    Rij[ "lj" "c" "O" ] = 3.65  # Cl-O
    Rij[ "lj" "O" "c" ] = 3.65  # O-Cl
    Rij[ "lj" "c" "P" ] = 4.14  # Cl-P
    Rij[ "lj" "P" "c" ] = 4.14  # P-Cl
    Rij[ "lj" "c" "S" ] = 4.04  # Cl-S
    Rij[ "lj" "S" "c" ] = 4.04  # S-Cl
    Rij[ "lj" "c" "H" ] = 3.04  # Cl-H
    Rij[ "lj" "H" "c" ] = 3.04  # H-Cl
    Rij[ "lj" "c" "f" ] = 2.69  # Cl-Fe
    Rij[ "lj" "f" "c" ] = 2.69  # Fe-Cl
    Rij[ "lj" "c" "F" ] = 3.59  # Cl-F
    Rij[ "lj" "F" "c" ] = 3.59  # F-Cl
    Rij[ "lj" "c" "c" ] = 4.09  # Cl-Cl
    Rij[ "lj" "c" "b" ] = 4.21  # Cl-Br
    Rij[ "lj" "b" "c" ] = 4.21  # Br-Cl
    Rij[ "lj" "c" "I" ] = 4.40  # Cl-I
    Rij[ "lj" "I" "c" ] = 4.40  # I-Cl
    Rij[ "lj" "c" "M" ] = 2.69  # Cl-Mg
    Rij[ "lj" "M" "c" ] = 2.69  # Mg-Cl
    Rij[ "lj" "c" "Z" ] = 2.79  # Cl-Zn
    Rij[ "lj" "Z" "c" ] = 2.79  # Zn-Cl
    Rij[ "lj" "c" "L" ] = 3.04  # Cl-Ca
    Rij[ "lj" "L" "c" ] = 3.04  # Ca-Cl
    Rij[ "lj" "c" "X" ] = 3.04  # Cl-Xx
    Rij[ "lj" "X" "c" ] = 3.04  # Xx-Cl

    Rij[ "lj" "b" "C" ] = 4.17  # Br-C
    Rij[ "lj" "C" "b" ] = 4.17  # C-Br
    Rij[ "lj" "b" "N" ] = 3.92  # Br-N
    Rij[ "lj" "N" "b" ] = 3.92  # N-Br
    Rij[ "lj" "b" "O" ] = 3.77  # Br-O
    Rij[ "lj" "O" "b" ] = 3.77  # O-Br
    Rij[ "lj" "b" "P" ] = 4.27  # Br-P
    Rij[ "lj" "P" "b" ] = 4.27  # P-Br
    Rij[ "lj" "b" "S" ] = 4.17  # Br-S
    Rij[ "lj" "S" "b" ] = 4.17  # S-Br
    Rij[ "lj" "b" "H" ] = 3.17  # Br-H
    Rij[ "lj" "H" "b" ] = 3.17  # H-Br
    Rij[ "lj" "b" "f" ] = 2.81  # Br-Fe
    Rij[ "lj" "f" "b" ] = 2.81  # Fe-Br
    Rij[ "lj" "b" "F" ] = 3.71  # Br-F
    Rij[ "lj" "F" "b" ] = 3.71  # F-Br
    Rij[ "lj" "b" "c" ] = 4.21  # Br-Cl
    Rij[ "lj" "c" "b" ] = 4.21  # Cl-Br
    Rij[ "lj" "b" "b" ] = 4.33  # Br-Br
    Rij[ "lj" "b" "I" ] = 4.53  # Br-I
    Rij[ "lj" "I" "b" ] = 4.53  # I-Br
    Rij[ "lj" "b" "M" ] = 2.81  # Br-Mg
    Rij[ "lj" "M" "b" ] = 2.81  # Mg-Br
    Rij[ "lj" "b" "Z" ] = 2.91  # Br-Zn
    Rij[ "lj" "Z" "b" ] = 2.91  # Zn-Br
    Rij[ "lj" "b" "L" ] = 3.16  # Br-Ca
    Rij[ "lj" "L" "b" ] = 3.16  # Ca-Br
    Rij[ "lj" "b" "X" ] = 3.17  # Br-Xx
    Rij[ "lj" "X" "b" ] = 3.17  # Xx-Br

    Rij[ "lj" "I" "C" ] = 4.36  # I-C
    Rij[ "lj" "C" "I" ] = 4.36  # C-I
    Rij[ "lj" "I" "N" ] = 4.11  # I-N
    Rij[ "lj" "N" "I" ] = 4.11  # N-I
    Rij[ "lj" "I" "O" ] = 3.96  # I-O
    Rij[ "lj" "O" "I" ] = 3.96  # O-I
    Rij[ "lj" "I" "P" ] = 4.46  # I-P
    Rij[ "lj" "P" "I" ] = 4.46  # P-I
    Rij[ "lj" "I" "S" ] = 4.36  # I-S
    Rij[ "lj" "S" "I" ] = 4.36  # S-I
    Rij[ "lj" "I" "H" ] = 3.36  # I-H
    Rij[ "lj" "H" "I" ] = 3.36  # H-I
    Rij[ "lj" "I" "f" ] = 3.01  # I-Fe
    Rij[ "lj" "f" "I" ] = 3.01  # Fe-I
    Rij[ "lj" "I" "F" ] = 3.90  # I-F
    Rij[ "lj" "F" "I" ] = 3.90  # F-I
    Rij[ "lj" "I" "c" ] = 4.40  # I-Cl
    Rij[ "lj" "c" "I" ] = 4.40  # Cl-I
    Rij[ "lj" "I" "b" ] = 4.53  # I-Br
    Rij[ "lj" "b" "I" ] = 4.53  # Br-I
    Rij[ "lj" "I" "I" ] = 4.72  # I-I
    Rij[ "lj" "I" "M" ] = 3.01  # I-Mg
    Rij[ "lj" "M" "I" ] = 3.01  # Mg-I
    Rij[ "lj" "I" "Z" ] = 3.10  # I-Zn
    Rij[ "lj" "Z" "I" ] = 3.10  # Zn-I
    Rij[ "lj" "I" "L" ] = 3.35  # I-Ca
    Rij[ "lj" "L" "I" ] = 3.35  # Ca-I
    Rij[ "lj" "I" "X" ] = 3.36  # I-Xx
    Rij[ "lj" "X" "I" ] = 3.36  # Xx-I

    Rij[ "lj" "M" "C" ] = 2.65  # Mg-C
    Rij[ "lj" "C" "M" ] = 2.65  # C-Mg
    Rij[ "lj" "M" "N" ] = 2.40  # Mg-N
    Rij[ "lj" "N" "M" ] = 2.40  # N-Mg
    Rij[ "lj" "M" "O" ] = 2.25  # Mg-O
    Rij[ "lj" "O" "M" ] = 2.25  # O-Mg
    Rij[ "lj" "M" "P" ] = 2.75  # Mg-P
    Rij[ "lj" "P" "M" ] = 2.75  # P-Mg
    Rij[ "lj" "M" "S" ] = 2.65  # Mg-S
    Rij[ "lj" "S" "M" ] = 2.65  # S-Mg
    Rij[ "lj" "M" "H" ] = 1.65  # Mg-H
    Rij[ "lj" "H" "M" ] = 1.65  # H-Mg
    Rij[ "lj" "M" "f" ] = 1.30  # Mg-Fe
    Rij[ "lj" "f" "M" ] = 1.30  # Fe-Mg
    Rij[ "lj" "M" "F" ] = 2.19  # Mg-F
    Rij[ "lj" "F" "M" ] = 2.19  # F-Mg
    Rij[ "lj" "M" "c" ] = 2.69  # Mg-Cl
    Rij[ "lj" "c" "M" ] = 2.69  # Cl-Mg
    Rij[ "lj" "M" "b" ] = 2.81  # Mg-Br
    Rij[ "lj" "b" "M" ] = 2.81  # Br-Mg
    Rij[ "lj" "M" "I" ] = 3.01  # Mg-I
    Rij[ "lj" "I" "M" ] = 3.01  # I-Mg
    Rij[ "lj" "M" "M" ] = 1.30  # Mg-Mg
    Rij[ "lj" "M" "Z" ] = 1.39  # Mg-Zn
    Rij[ "lj" "Z" "M" ] = 1.39  # Zn-Mg
    Rij[ "lj" "M" "L" ] = 1.64  # Mg-Ca
    Rij[ "lj" "L" "M" ] = 1.64  # Ca-Mg
    Rij[ "lj" "M" "X" ] = 1.65  # Mg-Xx
    Rij[ "lj" "X" "M" ] = 1.65  # Xx-Mg

    Rij[ "lj" "Z" "C" ] = 2.74  # Zn-C
    Rij[ "lj" "C" "Z" ] = 2.74  # C-Zn
    Rij[ "lj" "Z" "N" ] = 2.49  # Zn-N
    Rij[ "lj" "N" "Z" ] = 2.49  # N-Zn
    Rij[ "lj" "Z" "O" ] = 2.34  # Zn-O
    Rij[ "lj" "O" "Z" ] = 2.34  # O-Zn
    Rij[ "lj" "Z" "P" ] = 2.84  # Zn-P
    Rij[ "lj" "P" "Z" ] = 2.84  # P-Zn
    Rij[ "lj" "Z" "S" ] = 2.74  # Zn-S
    Rij[ "lj" "S" "Z" ] = 2.74  # S-Zn
    Rij[ "lj" "Z" "H" ] = 1.74  # Zn-H
    Rij[ "lj" "H" "Z" ] = 1.74  # H-Zn
    Rij[ "lj" "Z" "f" ] = 1.39  # Zn-Fe
    Rij[ "lj" "f" "Z" ] = 1.39  # Fe-Zn
    Rij[ "lj" "Z" "F" ] = 2.29  # Zn-F
    Rij[ "lj" "F" "Z" ] = 2.29  # F-Zn
    Rij[ "lj" "Z" "c" ] = 2.79  # Zn-Cl
    Rij[ "lj" "c" "Z" ] = 2.79  # Cl-Zn
    Rij[ "lj" "Z" "b" ] = 2.91  # Zn-Br
    Rij[ "lj" "b" "Z" ] = 2.91  # Br-Zn
    Rij[ "lj" "Z" "I" ] = 3.10  # Zn-I
    Rij[ "lj" "I" "Z" ] = 3.10  # I-Zn
    Rij[ "lj" "Z" "M" ] = 1.39  # Zn-Mg
    Rij[ "lj" "M" "Z" ] = 1.39  # Mg-Zn
    Rij[ "lj" "Z" "Z" ] = 1.48  # Zn-Zn
    Rij[ "lj" "Z" "L" ] = 1.73  # Zn-Ca
    Rij[ "lj" "L" "Z" ] = 1.73  # Ca-Zn
    Rij[ "lj" "Z" "X" ] = 1.74  # Zn-Xx
    Rij[ "lj" "X" "Z" ] = 1.74  # Xx-Zn

    Rij[ "lj" "L" "C" ] = 2.99  # Ca-C
    Rij[ "lj" "C" "L" ] = 2.99  # C-Ca
    Rij[ "lj" "L" "N" ] = 2.74  # Ca-N
    Rij[ "lj" "N" "L" ] = 2.74  # N-Ca
    Rij[ "lj" "L" "O" ] = 2.59  # Ca-O
    Rij[ "lj" "O" "L" ] = 2.59  # O-Ca
    Rij[ "lj" "L" "P" ] = 3.09  # Ca-P
    Rij[ "lj" "P" "L" ] = 3.09  # P-Ca
    Rij[ "lj" "L" "S" ] = 2.99  # Ca-S
    Rij[ "lj" "S" "L" ] = 2.99  # S-Ca
    Rij[ "lj" "L" "H" ] = 1.99  # Ca-H
    Rij[ "lj" "H" "L" ] = 1.99  # H-Ca
    Rij[ "lj" "L" "f" ] = 1.64  # Ca-Fe
    Rij[ "lj" "f" "L" ] = 1.64  # Fe-Ca
    Rij[ "lj" "L" "F" ] = 2.54  # Ca-F
    Rij[ "lj" "F" "L" ] = 2.54  # F-Ca
    Rij[ "lj" "L" "c" ] = 3.04  # Ca-Cl
    Rij[ "lj" "c" "L" ] = 3.04  # Cl-Ca
    Rij[ "lj" "L" "b" ] = 3.16  # Ca-Br
    Rij[ "lj" "b" "L" ] = 3.16  # Br-Ca
    Rij[ "lj" "L" "I" ] = 3.35  # Ca-I
    Rij[ "lj" "I" "L" ] = 3.35  # I-Ca
    Rij[ "lj" "L" "M" ] = 1.64  # Ca-Mg
    Rij[ "lj" "M" "L" ] = 1.64  # Mg-Ca
    Rij[ "lj" "L" "Z" ] = 1.73  # Ca-Zn
    Rij[ "lj" "Z" "L" ] = 1.73  # Zn-Ca
    Rij[ "lj" "L" "L" ] = 1.98  # Ca-Ca
    Rij[ "lj" "L" "X" ] = 1.99  # Ca-Xx
    Rij[ "lj" "X" "L" ] = 1.99  # Xx-Ca

    Rij[ "lj" "X" "C" ] = 3.00  # Xx-C
    Rij[ "lj" "C" "X" ] = 3.00  # C-Xx
    Rij[ "lj" "X" "N" ] = 2.75  # Xx-N
    Rij[ "lj" "N" "X" ] = 2.75  # N-Xx
    Rij[ "lj" "X" "O" ] = 2.60  # Xx-O
    Rij[ "lj" "O" "X" ] = 2.60  # O-Xx
    Rij[ "lj" "X" "P" ] = 3.10  # Xx-P
    Rij[ "lj" "P" "X" ] = 3.10  # P-Xx
    Rij[ "lj" "X" "S" ] = 3.00  # Xx-S
    Rij[ "lj" "S" "X" ] = 3.00  # S-Xx
    Rij[ "lj" "X" "H" ] = 2.00  # Xx-H
    Rij[ "lj" "H" "X" ] = 2.00  # H-Xx
    Rij[ "lj" "X" "f" ] = 1.65  # Xx-Fe
    Rij[ "lj" "f" "X" ] = 1.65  # Fe-Xx
    Rij[ "lj" "X" "F" ] = 2.54  # Xx-F
    Rij[ "lj" "F" "X" ] = 2.54  # F-Xx
    Rij[ "lj" "X" "c" ] = 3.04  # Xx-Cl
    Rij[ "lj" "c" "X" ] = 3.04  # Cl-Xx
    Rij[ "lj" "X" "b" ] = 3.17  # Xx-Br
    Rij[ "lj" "b" "X" ] = 3.17  # Br-Xx
    Rij[ "lj" "X" "I" ] = 3.36  # Xx-I
    Rij[ "lj" "I" "X" ] = 3.36  # I-Xx
    Rij[ "lj" "X" "M" ] = 1.65  # Xx-Mg
    Rij[ "lj" "M" "X" ] = 1.65  # Mg-Xx
    Rij[ "lj" "X" "Z" ] = 1.74  # Xx-Zn
    Rij[ "lj" "Z" "X" ] = 1.74  # Zn-Xx
    Rij[ "lj" "X" "L" ] = 1.99  # Xx-Ca
    Rij[ "lj" "L" "X" ] = 1.99  # Ca-Xx
    Rij[ "lj" "X" "X" ] = 2.00  # Xx-Xx

    # Rij[ "lj" "C" "A" ] = Rij[ "lj" "C" "C" ]
    # Rij[ "lj" "A" "C" ] = Rij[ "lj" "C" "A" ]
    # Rij[ "lj" "A" "A" ] = Rij[ "lj" "C" "C" ]
    # Rij[ "lj" "A" "N" ] = Rij[ "lj" "C" "N" ]
    # Rij[ "lj" "A" "O" ] = Rij[ "lj" "C" "O" ]
    # Rij[ "lj" "A" "S" ] = Rij[ "lj" "C" "S" ]
    # Rij[ "lj" "A" "H" ] = Rij[ "lj" "C" "H" ]
    # Rij[ "lj" "N" "A" ] = Rij[ "lj" "A" "N" ]
    # Rij[ "lj" "O" "A" ] = Rij[ "lj" "A" "O" ]
    # Rij[ "lj" "S" "A" ] = Rij[ "lj" "A" "S" ]
    # Rij[ "lj" "H" "A" ] = Rij[ "lj" "A" "H" ]
    # Rij[ "lj" "A" "X" ] = Rij[ "lj" "C" "X" ]
    # Rij[ "lj" "X" "A" ] = Rij[ "lj" "A" "X" ]

    # A is aromatic C!
    Rij[ "lj" "C" "A" ] = 4.00  # C-C
    Rij[ "lj" "A" "C" ] = 4.00  # C-C
    Rij[ "lj" "A" "N" ] = 3.75  # C-N
    Rij[ "lj" "N" "A" ] = 3.75  # N-C
    Rij[ "lj" "A" "O" ] = 3.60  # C-O
    Rij[ "lj" "O" "A" ] = 3.60  # O-C
    Rij[ "lj" "A" "P" ] = 4.10  # C-P
    Rij[ "lj" "P" "A" ] = 4.10  # P-C
    Rij[ "lj" "A" "S" ] = 4.00  # C-S
    Rij[ "lj" "S" "A" ] = 4.00  # S-C
    Rij[ "lj" "A" "H" ] = 3.00  # C-H
    Rij[ "lj" "H" "A" ] = 3.00  # H-C
    Rij[ "lj" "A" "f" ] = 2.65  # C-Fe
    Rij[ "lj" "f" "A" ] = 2.65  # Fe-C
    Rij[ "lj" "A" "F" ] = 3.54  # C-F
    Rij[ "lj" "F" "A" ] = 3.54  # F-C
    Rij[ "lj" "A" "c" ] = 4.04  # C-Cl
    Rij[ "lj" "c" "A" ] = 4.04  # Cl-C
    Rij[ "lj" "A" "b" ] = 4.17  # C-Br
    Rij[ "lj" "b" "A" ] = 4.17  # Br-C
    Rij[ "lj" "A" "I" ] = 4.36  # C-I
    Rij[ "lj" "I" "A" ] = 4.36  # I-C
    Rij[ "lj" "A" "M" ] = 2.65  # C-Mg
    Rij[ "lj" "M" "A" ] = 2.65  # Mg-C
    Rij[ "lj" "A" "Z" ] = 2.74  # C-Zn
    Rij[ "lj" "Z" "A" ] = 2.74  # Zn-C
    Rij[ "lj" "A" "L" ] = 2.99  # C-Ca
    Rij[ "lj" "L" "A" ] = 2.99  # Ca-C
    Rij[ "lj" "A" "X" ] = 3.00  # C-Xx
    Rij[ "lj" "X" "A" ] = 3.00  # Xx-C

    #
    # AutoDock Binding Free Energy Model 140n
    # New well-depths using new Solvation Model, 
    # multiplied by van der Waals coefficient, 0.1485
    #

    #
    # Well-depths prior to Solvation Model, multiplied by FE_vdW_coeff
    #
    epsij[ "lj" "C" "C" ] = 0.1500 * FE_vdW_coeff  # C-C
    epsij[ "lj" "C" "N" ] = 0.1549 * FE_vdW_coeff  # C-N
    epsij[ "lj" "N" "C" ] = 0.1549 * FE_vdW_coeff  # N-C
    epsij[ "lj" "C" "O" ] = 0.1732 * FE_vdW_coeff  # C-O
    epsij[ "lj" "O" "C" ] = 0.1732 * FE_vdW_coeff  # O-C
    epsij[ "lj" "C" "P" ] = 0.1732 * FE_vdW_coeff  # C-P
    epsij[ "lj" "P" "C" ] = 0.1732 * FE_vdW_coeff  # P-C
    epsij[ "lj" "C" "S" ] = 0.1732 * FE_vdW_coeff  # C-S
    epsij[ "lj" "S" "C" ] = 0.1732 * FE_vdW_coeff  # S-C
    epsij[ "lj" "C" "H" ] = 0.0548 * FE_vdW_coeff  # C-H
    epsij[ "lj" "H" "C" ] = 0.0548 * FE_vdW_coeff  # H-C
    epsij[ "lj" "C" "f" ] = 0.0387 * FE_vdW_coeff  # C-Fe
    epsij[ "lj" "f" "C" ] = 0.0387 * FE_vdW_coeff  # Fe-C
    epsij[ "lj" "C" "F" ] = 0.1095 * FE_vdW_coeff  # C-F
    epsij[ "lj" "F" "C" ] = 0.1095 * FE_vdW_coeff  # F-C
    epsij[ "lj" "C" "c" ] = 0.2035 * FE_vdW_coeff  # C-Cl
    epsij[ "lj" "c" "C" ] = 0.2035 * FE_vdW_coeff  # Cl-C
    epsij[ "lj" "C" "b" ] = 0.2416 * FE_vdW_coeff  # C-Br
    epsij[ "lj" "b" "C" ] = 0.2416 * FE_vdW_coeff  # Br-C
    epsij[ "lj" "C" "I" ] = 0.2877 * FE_vdW_coeff  # C-I
    epsij[ "lj" "I" "C" ] = 0.2877 * FE_vdW_coeff  # I-C
    epsij[ "lj" "C" "M" ] = 0.3623 * FE_vdW_coeff  # C-Mg
    epsij[ "lj" "M" "C" ] = 0.3623 * FE_vdW_coeff  # Mg-C
    epsij[ "lj" "C" "Z" ] = 0.2872 * FE_vdW_coeff  # C-Zn
    epsij[ "lj" "Z" "C" ] = 0.2872 * FE_vdW_coeff  # Zn-C
    epsij[ "lj" "C" "L" ] = 0.2872 * FE_vdW_coeff  # C-Ca
    epsij[ "lj" "L" "C" ] = 0.2872 * FE_vdW_coeff  # Ca-C
    epsij[ "lj" "C" "X" ] = 0.0548 * FE_vdW_coeff  # C-Xx
    epsij[ "lj" "X" "C" ] = 0.0548 * FE_vdW_coeff  # Xx-C

    epsij[ "lj" "N" "C" ] = 0.1549 * FE_vdW_coeff  # N-C
    epsij[ "lj" "C" "N" ] = 0.1549 * FE_vdW_coeff  # C-N
    epsij[ "lj" "N" "N" ] = 0.1600 * FE_vdW_coeff  # N-N
    epsij[ "lj" "N" "O" ] = 0.1789 * FE_vdW_coeff  # N-O
    epsij[ "lj" "O" "N" ] = 0.1789 * FE_vdW_coeff  # O-N
    epsij[ "lj" "N" "P" ] = 0.1789 * FE_vdW_coeff  # N-P
    epsij[ "lj" "P" "N" ] = 0.1789 * FE_vdW_coeff  # P-N
    epsij[ "lj" "N" "S" ] = 0.1789 * FE_vdW_coeff  # N-S
    epsij[ "lj" "S" "N" ] = 0.1789 * FE_vdW_coeff  # S-N
    epsij[ "lj" "N" "H" ] = 0.0566 * FE_vdW_coeff  # N-H
    epsij[ "lj" "H" "N" ] = 0.0566 * FE_vdW_coeff  # H-N
    epsij[ "lj" "N" "f" ] = 0.0400 * FE_vdW_coeff  # N-Fe
    epsij[ "lj" "f" "N" ] = 0.0400 * FE_vdW_coeff  # Fe-N
    epsij[ "lj" "N" "F" ] = 0.1131 * FE_vdW_coeff  # N-F
    epsij[ "lj" "F" "N" ] = 0.1131 * FE_vdW_coeff  # F-N
    epsij[ "lj" "N" "c" ] = 0.2101 * FE_vdW_coeff  # N-Cl
    epsij[ "lj" "c" "N" ] = 0.2101 * FE_vdW_coeff  # Cl-N
    epsij[ "lj" "N" "b" ] = 0.2495 * FE_vdW_coeff  # N-Br
    epsij[ "lj" "b" "N" ] = 0.2495 * FE_vdW_coeff  # Br-N
    epsij[ "lj" "N" "I" ] = 0.2972 * FE_vdW_coeff  # N-I
    epsij[ "lj" "I" "N" ] = 0.2972 * FE_vdW_coeff  # I-N
    epsij[ "lj" "N" "M" ] = 0.3742 * FE_vdW_coeff  # N-Mg
    epsij[ "lj" "M" "N" ] = 0.3742 * FE_vdW_coeff  # Mg-N
    epsij[ "lj" "N" "Z" ] = 0.2966 * FE_vdW_coeff  # N-Zn
    epsij[ "lj" "Z" "N" ] = 0.2966 * FE_vdW_coeff  # Zn-N
    epsij[ "lj" "N" "L" ] = 0.2966 * FE_vdW_coeff  # N-Ca
    epsij[ "lj" "L" "N" ] = 0.2966 * FE_vdW_coeff  # Ca-N
    epsij[ "lj" "N" "X" ] = 0.0566 * FE_vdW_coeff  # N-Xx
    epsij[ "lj" "X" "N" ] = 0.0566 * FE_vdW_coeff  # Xx-N

    epsij[ "lj" "O" "C" ] = 0.1732 * FE_vdW_coeff  # O-C
    epsij[ "lj" "C" "O" ] = 0.1732 * FE_vdW_coeff  # C-O
    epsij[ "lj" "O" "N" ] = 0.1789 * FE_vdW_coeff  # O-N
    epsij[ "lj" "N" "O" ] = 0.1789 * FE_vdW_coeff  # N-O
    epsij[ "lj" "O" "O" ] = 0.2000 * FE_vdW_coeff  # O-O
    epsij[ "lj" "O" "P" ] = 0.2000 * FE_vdW_coeff  # O-P
    epsij[ "lj" "P" "O" ] = 0.2000 * FE_vdW_coeff  # P-O
    epsij[ "lj" "O" "S" ] = 0.2000 * FE_vdW_coeff  # O-S
    epsij[ "lj" "S" "O" ] = 0.2000 * FE_vdW_coeff  # S-O
    epsij[ "lj" "O" "H" ] = 0.0632 * FE_vdW_coeff  # O-H
    epsij[ "lj" "H" "O" ] = 0.0632 * FE_vdW_coeff  # H-O
    epsij[ "lj" "O" "f" ] = 0.0447 * FE_vdW_coeff  # O-Fe
    epsij[ "lj" "f" "O" ] = 0.0447 * FE_vdW_coeff  # Fe-O
    epsij[ "lj" "O" "F" ] = 0.1265 * FE_vdW_coeff  # O-F
    epsij[ "lj" "F" "O" ] = 0.1265 * FE_vdW_coeff  # F-O
    epsij[ "lj" "O" "c" ] = 0.2349 * FE_vdW_coeff  # O-Cl
    epsij[ "lj" "c" "O" ] = 0.2349 * FE_vdW_coeff  # Cl-O
    epsij[ "lj" "O" "b" ] = 0.2789 * FE_vdW_coeff  # O-Br
    epsij[ "lj" "b" "O" ] = 0.2789 * FE_vdW_coeff  # Br-O
    epsij[ "lj" "O" "I" ] = 0.3323 * FE_vdW_coeff  # O-I
    epsij[ "lj" "I" "O" ] = 0.3323 * FE_vdW_coeff  # I-O
    epsij[ "lj" "O" "M" ] = 0.4183 * FE_vdW_coeff  # O-Mg
    epsij[ "lj" "M" "O" ] = 0.4183 * FE_vdW_coeff  # Mg-O
    epsij[ "lj" "O" "Z" ] = 0.3317 * FE_vdW_coeff  # O-Zn
    epsij[ "lj" "Z" "O" ] = 0.3317 * FE_vdW_coeff  # Zn-O
    epsij[ "lj" "O" "L" ] = 0.3317 * FE_vdW_coeff  # O-Ca
    epsij[ "lj" "L" "O" ] = 0.3317 * FE_vdW_coeff  # Ca-O
    epsij[ "lj" "O" "X" ] = 0.0632 * FE_vdW_coeff  # O-Xx
    epsij[ "lj" "X" "O" ] = 0.0632 * FE_vdW_coeff  # Xx-O

    epsij[ "lj" "P" "C" ] = 0.1732 * FE_vdW_coeff  # P-C
    epsij[ "lj" "C" "P" ] = 0.1732 * FE_vdW_coeff  # C-P
    epsij[ "lj" "P" "N" ] = 0.1789 * FE_vdW_coeff  # P-N
    epsij[ "lj" "N" "P" ] = 0.1789 * FE_vdW_coeff  # N-P
    epsij[ "lj" "P" "O" ] = 0.2000 * FE_vdW_coeff  # P-O
    epsij[ "lj" "O" "P" ] = 0.2000 * FE_vdW_coeff  # O-P
    epsij[ "lj" "P" "P" ] = 0.2000 * FE_vdW_coeff  # P-P
    epsij[ "lj" "P" "S" ] = 0.2000 * FE_vdW_coeff  # P-S
    epsij[ "lj" "S" "P" ] = 0.2000 * FE_vdW_coeff  # S-P
    epsij[ "lj" "P" "H" ] = 0.0632 * FE_vdW_coeff  # P-H
    epsij[ "lj" "H" "P" ] = 0.0632 * FE_vdW_coeff  # H-P
    epsij[ "lj" "P" "f" ] = 0.0447 * FE_vdW_coeff  # P-Fe
    epsij[ "lj" "f" "P" ] = 0.0447 * FE_vdW_coeff  # Fe-P
    epsij[ "lj" "P" "F" ] = 0.1265 * FE_vdW_coeff  # P-F
    epsij[ "lj" "F" "P" ] = 0.1265 * FE_vdW_coeff  # F-P
    epsij[ "lj" "P" "c" ] = 0.2349 * FE_vdW_coeff  # P-Cl
    epsij[ "lj" "c" "P" ] = 0.2349 * FE_vdW_coeff  # Cl-P
    epsij[ "lj" "P" "b" ] = 0.2789 * FE_vdW_coeff  # P-Br
    epsij[ "lj" "b" "P" ] = 0.2789 * FE_vdW_coeff  # Br-P
    epsij[ "lj" "P" "I" ] = 0.3323 * FE_vdW_coeff  # P-I
    epsij[ "lj" "I" "P" ] = 0.3323 * FE_vdW_coeff  # I-P
    epsij[ "lj" "P" "M" ] = 0.4183 * FE_vdW_coeff  # P-Mg
    epsij[ "lj" "M" "P" ] = 0.4183 * FE_vdW_coeff  # Mg-P
    epsij[ "lj" "P" "Z" ] = 0.3317 * FE_vdW_coeff  # P-Zn
    epsij[ "lj" "Z" "P" ] = 0.3317 * FE_vdW_coeff  # Zn-P
    epsij[ "lj" "P" "L" ] = 0.3317 * FE_vdW_coeff  # P-Ca
    epsij[ "lj" "L" "P" ] = 0.3317 * FE_vdW_coeff  # Ca-P
    epsij[ "lj" "P" "X" ] = 0.0632 * FE_vdW_coeff  # P-Xx
    epsij[ "lj" "X" "P" ] = 0.0632 * FE_vdW_coeff  # Xx-P

    epsij[ "lj" "S" "C" ] = 0.1732 * FE_vdW_coeff  # S-C
    epsij[ "lj" "C" "S" ] = 0.1732 * FE_vdW_coeff  # C-S
    epsij[ "lj" "S" "N" ] = 0.1789 * FE_vdW_coeff  # S-N
    epsij[ "lj" "N" "S" ] = 0.1789 * FE_vdW_coeff  # N-S
    epsij[ "lj" "S" "O" ] = 0.2000 * FE_vdW_coeff  # S-O
    epsij[ "lj" "O" "S" ] = 0.2000 * FE_vdW_coeff  # O-S
    epsij[ "lj" "S" "P" ] = 0.2000 * FE_vdW_coeff  # S-P
    epsij[ "lj" "P" "S" ] = 0.2000 * FE_vdW_coeff  # P-S
    epsij[ "lj" "S" "S" ] = 0.2000 * FE_vdW_coeff  # S-S
    epsij[ "lj" "S" "H" ] = 0.0632 * FE_vdW_coeff  # S-H
    epsij[ "lj" "H" "S" ] = 0.0632 * FE_vdW_coeff  # H-S
    epsij[ "lj" "S" "f" ] = 0.0447 * FE_vdW_coeff  # S-Fe
    epsij[ "lj" "f" "S" ] = 0.0447 * FE_vdW_coeff  # Fe-S
    epsij[ "lj" "S" "F" ] = 0.1265 * FE_vdW_coeff  # S-F
    epsij[ "lj" "F" "S" ] = 0.1265 * FE_vdW_coeff  # F-S
    epsij[ "lj" "S" "c" ] = 0.2349 * FE_vdW_coeff  # S-Cl
    epsij[ "lj" "c" "S" ] = 0.2349 * FE_vdW_coeff  # Cl-S
    epsij[ "lj" "S" "b" ] = 0.2789 * FE_vdW_coeff  # S-Br
    epsij[ "lj" "b" "S" ] = 0.2789 * FE_vdW_coeff  # Br-S
    epsij[ "lj" "S" "I" ] = 0.3323 * FE_vdW_coeff  # S-I
    epsij[ "lj" "I" "S" ] = 0.3323 * FE_vdW_coeff  # I-S
    epsij[ "lj" "S" "M" ] = 0.4183 * FE_vdW_coeff  # S-Mg
    epsij[ "lj" "M" "S" ] = 0.4183 * FE_vdW_coeff  # Mg-S
    epsij[ "lj" "S" "Z" ] = 0.3317 * FE_vdW_coeff  # S-Zn
    epsij[ "lj" "Z" "S" ] = 0.3317 * FE_vdW_coeff  # Zn-S
    epsij[ "lj" "S" "L" ] = 0.3317 * FE_vdW_coeff  # S-Ca
    epsij[ "lj" "L" "S" ] = 0.3317 * FE_vdW_coeff  # Ca-S
    epsij[ "lj" "S" "X" ] = 0.0632 * FE_vdW_coeff  # S-Xx
    epsij[ "lj" "X" "S" ] = 0.0632 * FE_vdW_coeff  # Xx-S

    epsij[ "lj" "H" "C" ] = 0.0548 * FE_vdW_coeff  # H-C
    epsij[ "lj" "C" "H" ] = 0.0548 * FE_vdW_coeff  # C-H
    epsij[ "lj" "H" "N" ] = 0.0566 * FE_vdW_coeff  # H-N
    epsij[ "lj" "N" "H" ] = 0.0566 * FE_vdW_coeff  # N-H
    epsij[ "lj" "H" "O" ] = 0.0632 * FE_vdW_coeff  # H-O
    epsij[ "lj" "O" "H" ] = 0.0632 * FE_vdW_coeff  # O-H
    epsij[ "lj" "H" "P" ] = 0.0632 * FE_vdW_coeff  # H-P
    epsij[ "lj" "P" "H" ] = 0.0632 * FE_vdW_coeff  # P-H
    epsij[ "lj" "H" "S" ] = 0.0632 * FE_vdW_coeff  # H-S
    epsij[ "lj" "S" "H" ] = 0.0632 * FE_vdW_coeff  # S-H
    epsij[ "lj" "H" "H" ] = 0.0200 * FE_vdW_coeff  # H-H
    epsij[ "lj" "H" "f" ] = 0.0141 * FE_vdW_coeff  # H-Fe
    epsij[ "lj" "f" "H" ] = 0.0141 * FE_vdW_coeff  # Fe-H
    epsij[ "lj" "H" "F" ] = 0.0400 * FE_vdW_coeff  # H-F
    epsij[ "lj" "F" "H" ] = 0.0400 * FE_vdW_coeff  # F-H
    epsij[ "lj" "H" "c" ] = 0.0743 * FE_vdW_coeff  # H-Cl
    epsij[ "lj" "c" "H" ] = 0.0743 * FE_vdW_coeff  # Cl-H
    epsij[ "lj" "H" "b" ] = 0.0882 * FE_vdW_coeff  # H-Br
    epsij[ "lj" "b" "H" ] = 0.0882 * FE_vdW_coeff  # Br-H
    epsij[ "lj" "H" "I" ] = 0.1051 * FE_vdW_coeff  # H-I
    epsij[ "lj" "I" "H" ] = 0.1051 * FE_vdW_coeff  # I-H
    epsij[ "lj" "H" "M" ] = 0.1323 * FE_vdW_coeff  # H-Mg
    epsij[ "lj" "M" "H" ] = 0.1323 * FE_vdW_coeff  # Mg-H
    epsij[ "lj" "H" "Z" ] = 0.1049 * FE_vdW_coeff  # H-Zn
    epsij[ "lj" "Z" "H" ] = 0.1049 * FE_vdW_coeff  # Zn-H
    epsij[ "lj" "H" "L" ] = 0.1049 * FE_vdW_coeff  # H-Ca
    epsij[ "lj" "L" "H" ] = 0.1049 * FE_vdW_coeff  # Ca-H
    epsij[ "lj" "H" "X" ] = 0.0200 * FE_vdW_coeff  # H-Xx
    epsij[ "lj" "X" "H" ] = 0.0200 * FE_vdW_coeff  # Xx-H

    epsij[ "lj" "f" "C" ] = 0.0387 * FE_vdW_coeff  # Fe-C
    epsij[ "lj" "C" "f" ] = 0.0387 * FE_vdW_coeff  # C-Fe
    epsij[ "lj" "f" "N" ] = 0.0400 * FE_vdW_coeff  # Fe-N
    epsij[ "lj" "N" "f" ] = 0.0400 * FE_vdW_coeff  # N-Fe
    epsij[ "lj" "f" "O" ] = 0.0447 * FE_vdW_coeff  # Fe-O
    epsij[ "lj" "O" "f" ] = 0.0447 * FE_vdW_coeff  # O-Fe
    epsij[ "lj" "f" "P" ] = 0.0447 * FE_vdW_coeff  # Fe-P
    epsij[ "lj" "P" "f" ] = 0.0447 * FE_vdW_coeff  # P-Fe
    epsij[ "lj" "f" "S" ] = 0.0447 * FE_vdW_coeff  # Fe-S
    epsij[ "lj" "S" "f" ] = 0.0447 * FE_vdW_coeff  # S-Fe
    epsij[ "lj" "f" "H" ] = 0.0141 * FE_vdW_coeff  # Fe-H
    epsij[ "lj" "H" "f" ] = 0.0141 * FE_vdW_coeff  # H-Fe
    epsij[ "lj" "f" "f" ] = 0.0100 * FE_vdW_coeff  # Fe-Fe
    epsij[ "lj" "f" "F" ] = 0.0283 * FE_vdW_coeff  # Fe-F
    epsij[ "lj" "F" "f" ] = 0.0283 * FE_vdW_coeff  # F-Fe
    epsij[ "lj" "f" "c" ] = 0.0525 * FE_vdW_coeff  # Fe-Cl
    epsij[ "lj" "c" "f" ] = 0.0525 * FE_vdW_coeff  # Cl-Fe
    epsij[ "lj" "f" "b" ] = 0.0624 * FE_vdW_coeff  # Fe-Br
    epsij[ "lj" "b" "f" ] = 0.0624 * FE_vdW_coeff  # Br-Fe
    epsij[ "lj" "f" "I" ] = 0.0743 * FE_vdW_coeff  # Fe-I
    epsij[ "lj" "I" "f" ] = 0.0743 * FE_vdW_coeff  # I-Fe
    epsij[ "lj" "f" "M" ] = 0.0935 * FE_vdW_coeff  # Fe-Mg
    epsij[ "lj" "M" "f" ] = 0.0935 * FE_vdW_coeff  # Mg-Fe
    epsij[ "lj" "f" "Z" ] = 0.0742 * FE_vdW_coeff  # Fe-Zn
    epsij[ "lj" "Z" "f" ] = 0.0742 * FE_vdW_coeff  # Zn-Fe
    epsij[ "lj" "f" "L" ] = 0.0742 * FE_vdW_coeff  # Fe-Ca
    epsij[ "lj" "L" "f" ] = 0.0742 * FE_vdW_coeff  # Ca-Fe
    epsij[ "lj" "f" "X" ] = 0.0141 * FE_vdW_coeff  # Fe-Xx
    epsij[ "lj" "X" "f" ] = 0.0141 * FE_vdW_coeff  # Xx-Fe

    epsij[ "lj" "F" "C" ] = 0.1095 * FE_vdW_coeff  # F-C
    epsij[ "lj" "C" "F" ] = 0.1095 * FE_vdW_coeff  # C-F
    epsij[ "lj" "F" "N" ] = 0.1131 * FE_vdW_coeff  # F-N
    epsij[ "lj" "N" "F" ] = 0.1131 * FE_vdW_coeff  # N-F
    epsij[ "lj" "F" "O" ] = 0.1265 * FE_vdW_coeff  # F-O
    epsij[ "lj" "O" "F" ] = 0.1265 * FE_vdW_coeff  # O-F
    epsij[ "lj" "F" "P" ] = 0.1265 * FE_vdW_coeff  # F-P
    epsij[ "lj" "P" "F" ] = 0.1265 * FE_vdW_coeff  # P-F
    epsij[ "lj" "F" "S" ] = 0.1265 * FE_vdW_coeff  # F-S
    epsij[ "lj" "S" "F" ] = 0.1265 * FE_vdW_coeff  # S-F
    epsij[ "lj" "F" "H" ] = 0.0400 * FE_vdW_coeff  # F-H
    epsij[ "lj" "H" "F" ] = 0.0400 * FE_vdW_coeff  # H-F
    epsij[ "lj" "F" "f" ] = 0.0283 * FE_vdW_coeff  # F-Fe
    epsij[ "lj" "f" "F" ] = 0.0283 * FE_vdW_coeff  # Fe-F
    epsij[ "lj" "F" "F" ] = 0.0800 * FE_vdW_coeff  # F-F
    epsij[ "lj" "F" "c" ] = 0.1486 * FE_vdW_coeff  # F-Cl
    epsij[ "lj" "c" "F" ] = 0.1486 * FE_vdW_coeff  # Cl-F
    epsij[ "lj" "F" "b" ] = 0.1764 * FE_vdW_coeff  # F-Br
    epsij[ "lj" "b" "F" ] = 0.1764 * FE_vdW_coeff  # Br-F
    epsij[ "lj" "F" "I" ] = 0.2101 * FE_vdW_coeff  # F-I
    epsij[ "lj" "I" "F" ] = 0.2101 * FE_vdW_coeff  # I-F
    epsij[ "lj" "F" "M" ] = 0.2646 * FE_vdW_coeff  # F-Mg
    epsij[ "lj" "M" "F" ] = 0.2646 * FE_vdW_coeff  # Mg-F
    epsij[ "lj" "F" "Z" ] = 0.2098 * FE_vdW_coeff  # F-Zn
    epsij[ "lj" "Z" "F" ] = 0.2098 * FE_vdW_coeff  # Zn-F
    epsij[ "lj" "F" "L" ] = 0.2098 * FE_vdW_coeff  # F-Ca
    epsij[ "lj" "L" "F" ] = 0.2098 * FE_vdW_coeff  # Ca-F
    epsij[ "lj" "F" "X" ] = 0.0400 * FE_vdW_coeff  # F-Xx
    epsij[ "lj" "X" "F" ] = 0.0400 * FE_vdW_coeff  # Xx-F

    epsij[ "lj" "c" "C" ] = 0.2035 * FE_vdW_coeff  # Cl-C
    epsij[ "lj" "C" "c" ] = 0.2035 * FE_vdW_coeff  # C-Cl
    epsij[ "lj" "c" "N" ] = 0.2101 * FE_vdW_coeff  # Cl-N
    epsij[ "lj" "N" "c" ] = 0.2101 * FE_vdW_coeff  # N-Cl
    epsij[ "lj" "c" "O" ] = 0.2349 * FE_vdW_coeff  # Cl-O
    epsij[ "lj" "O" "c" ] = 0.2349 * FE_vdW_coeff  # O-Cl
    epsij[ "lj" "c" "P" ] = 0.2349 * FE_vdW_coeff  # Cl-P
    epsij[ "lj" "P" "c" ] = 0.2349 * FE_vdW_coeff  # P-Cl
    epsij[ "lj" "c" "S" ] = 0.2349 * FE_vdW_coeff  # Cl-S
    epsij[ "lj" "S" "c" ] = 0.2349 * FE_vdW_coeff  # S-Cl
    epsij[ "lj" "c" "H" ] = 0.0743 * FE_vdW_coeff  # Cl-H
    epsij[ "lj" "H" "c" ] = 0.0743 * FE_vdW_coeff  # H-Cl
    epsij[ "lj" "c" "f" ] = 0.0525 * FE_vdW_coeff  # Cl-Fe
    epsij[ "lj" "f" "c" ] = 0.0525 * FE_vdW_coeff  # Fe-Cl
    epsij[ "lj" "c" "F" ] = 0.1486 * FE_vdW_coeff  # Cl-F
    epsij[ "lj" "F" "c" ] = 0.1486 * FE_vdW_coeff  # F-Cl
    epsij[ "lj" "c" "c" ] = 0.2760 * FE_vdW_coeff  # Cl-Cl
    epsij[ "lj" "c" "b" ] = 0.3277 * FE_vdW_coeff  # Cl-Br
    epsij[ "lj" "b" "c" ] = 0.3277 * FE_vdW_coeff  # Br-Cl
    epsij[ "lj" "c" "I" ] = 0.3903 * FE_vdW_coeff  # Cl-I
    epsij[ "lj" "I" "c" ] = 0.3903 * FE_vdW_coeff  # I-Cl
    epsij[ "lj" "c" "M" ] = 0.4914 * FE_vdW_coeff  # Cl-Mg
    epsij[ "lj" "M" "c" ] = 0.4914 * FE_vdW_coeff  # Mg-Cl
    epsij[ "lj" "c" "Z" ] = 0.3896 * FE_vdW_coeff  # Cl-Zn
    epsij[ "lj" "Z" "c" ] = 0.3896 * FE_vdW_coeff  # Zn-Cl
    epsij[ "lj" "c" "L" ] = 0.3896 * FE_vdW_coeff  # Cl-Ca
    epsij[ "lj" "L" "c" ] = 0.3896 * FE_vdW_coeff  # Ca-Cl
    epsij[ "lj" "c" "X" ] = 0.0743 * FE_vdW_coeff  # Cl-Xx
    epsij[ "lj" "X" "c" ] = 0.0743 * FE_vdW_coeff  # Xx-Cl

    epsij[ "lj" "b" "C" ] = 0.2416 * FE_vdW_coeff  # Br-C
    epsij[ "lj" "C" "b" ] = 0.2416 * FE_vdW_coeff  # C-Br
    epsij[ "lj" "b" "N" ] = 0.2495 * FE_vdW_coeff  # Br-N
    epsij[ "lj" "N" "b" ] = 0.2495 * FE_vdW_coeff  # N-Br
    epsij[ "lj" "b" "O" ] = 0.2789 * FE_vdW_coeff  # Br-O
    epsij[ "lj" "O" "b" ] = 0.2789 * FE_vdW_coeff  # O-Br
    epsij[ "lj" "b" "P" ] = 0.2789 * FE_vdW_coeff  # Br-P
    epsij[ "lj" "P" "b" ] = 0.2789 * FE_vdW_coeff  # P-Br
    epsij[ "lj" "b" "S" ] = 0.2789 * FE_vdW_coeff  # Br-S
    epsij[ "lj" "S" "b" ] = 0.2789 * FE_vdW_coeff  # S-Br
    epsij[ "lj" "b" "H" ] = 0.0882 * FE_vdW_coeff  # Br-H
    epsij[ "lj" "H" "b" ] = 0.0882 * FE_vdW_coeff  # H-Br
    epsij[ "lj" "b" "f" ] = 0.0624 * FE_vdW_coeff  # Br-Fe
    epsij[ "lj" "f" "b" ] = 0.0624 * FE_vdW_coeff  # Fe-Br
    epsij[ "lj" "b" "F" ] = 0.1764 * FE_vdW_coeff  # Br-F
    epsij[ "lj" "F" "b" ] = 0.1764 * FE_vdW_coeff  # F-Br
    epsij[ "lj" "b" "c" ] = 0.3277 * FE_vdW_coeff  # Br-Cl
    epsij[ "lj" "c" "b" ] = 0.3277 * FE_vdW_coeff  # Cl-Br
    epsij[ "lj" "b" "b" ] = 0.3890 * FE_vdW_coeff  # Br-Br
    epsij[ "lj" "b" "I" ] = 0.4634 * FE_vdW_coeff  # Br-I
    epsij[ "lj" "I" "b" ] = 0.4634 * FE_vdW_coeff  # I-Br
    epsij[ "lj" "b" "M" ] = 0.5834 * FE_vdW_coeff  # Br-Mg
    epsij[ "lj" "M" "b" ] = 0.5834 * FE_vdW_coeff  # Mg-Br
    epsij[ "lj" "b" "Z" ] = 0.4625 * FE_vdW_coeff  # Br-Zn
    epsij[ "lj" "Z" "b" ] = 0.4625 * FE_vdW_coeff  # Zn-Br
    epsij[ "lj" "b" "L" ] = 0.4625 * FE_vdW_coeff  # Br-Ca
    epsij[ "lj" "L" "b" ] = 0.4625 * FE_vdW_coeff  # Ca-Br
    epsij[ "lj" "b" "X" ] = 0.0882 * FE_vdW_coeff  # Br-Xx
    epsij[ "lj" "X" "b" ] = 0.0882 * FE_vdW_coeff  # Xx-Br

    epsij[ "lj" "I" "C" ] = 0.2877 * FE_vdW_coeff  # I-C
    epsij[ "lj" "C" "I" ] = 0.2877 * FE_vdW_coeff  # C-I
    epsij[ "lj" "I" "N" ] = 0.2972 * FE_vdW_coeff  # I-N
    epsij[ "lj" "N" "I" ] = 0.2972 * FE_vdW_coeff  # N-I
    epsij[ "lj" "I" "O" ] = 0.3323 * FE_vdW_coeff  # I-O
    epsij[ "lj" "O" "I" ] = 0.3323 * FE_vdW_coeff  # O-I
    epsij[ "lj" "I" "P" ] = 0.3323 * FE_vdW_coeff  # I-P
    epsij[ "lj" "P" "I" ] = 0.3323 * FE_vdW_coeff  # P-I
    epsij[ "lj" "I" "S" ] = 0.3323 * FE_vdW_coeff  # I-S
    epsij[ "lj" "S" "I" ] = 0.3323 * FE_vdW_coeff  # S-I
    epsij[ "lj" "I" "H" ] = 0.1051 * FE_vdW_coeff  # I-H
    epsij[ "lj" "H" "I" ] = 0.1051 * FE_vdW_coeff  # H-I
    epsij[ "lj" "I" "f" ] = 0.0743 * FE_vdW_coeff  # I-Fe
    epsij[ "lj" "f" "I" ] = 0.0743 * FE_vdW_coeff  # Fe-I
    epsij[ "lj" "I" "F" ] = 0.2101 * FE_vdW_coeff  # I-F
    epsij[ "lj" "F" "I" ] = 0.2101 * FE_vdW_coeff  # F-I
    epsij[ "lj" "I" "c" ] = 0.3903 * FE_vdW_coeff  # I-Cl
    epsij[ "lj" "c" "I" ] = 0.3903 * FE_vdW_coeff  # Cl-I
    epsij[ "lj" "I" "b" ] = 0.4634 * FE_vdW_coeff  # I-Br
    epsij[ "lj" "b" "I" ] = 0.4634 * FE_vdW_coeff  # Br-I
    epsij[ "lj" "I" "I" ] = 0.5520 * FE_vdW_coeff  # I-I
    epsij[ "lj" "I" "M" ] = 0.6950 * FE_vdW_coeff  # I-Mg
    epsij[ "lj" "M" "I" ] = 0.6950 * FE_vdW_coeff  # Mg-I
    epsij[ "lj" "I" "Z" ] = 0.5510 * FE_vdW_coeff  # I-Zn
    epsij[ "lj" "Z" "I" ] = 0.5510 * FE_vdW_coeff  # Zn-I
    epsij[ "lj" "I" "L" ] = 0.5510 * FE_vdW_coeff  # I-Ca
    epsij[ "lj" "L" "I" ] = 0.5510 * FE_vdW_coeff  # Ca-I
    epsij[ "lj" "I" "X" ] = 0.1051 * FE_vdW_coeff  # I-Xx
    epsij[ "lj" "X" "I" ] = 0.1051 * FE_vdW_coeff  # Xx-I

    epsij[ "lj" "M" "C" ] = 0.3623 * FE_vdW_coeff  # Mg-C
    epsij[ "lj" "C" "M" ] = 0.3623 * FE_vdW_coeff  # C-Mg
    epsij[ "lj" "M" "N" ] = 0.3742 * FE_vdW_coeff  # Mg-N
    epsij[ "lj" "N" "M" ] = 0.3742 * FE_vdW_coeff  # N-Mg
    epsij[ "lj" "M" "O" ] = 0.4183 * FE_vdW_coeff  # Mg-O
    epsij[ "lj" "O" "M" ] = 0.4183 * FE_vdW_coeff  # O-Mg
    epsij[ "lj" "M" "P" ] = 0.4183 * FE_vdW_coeff  # Mg-P
    epsij[ "lj" "P" "M" ] = 0.4183 * FE_vdW_coeff  # P-Mg
    epsij[ "lj" "M" "S" ] = 0.4183 * FE_vdW_coeff  # Mg-S
    epsij[ "lj" "S" "M" ] = 0.4183 * FE_vdW_coeff  # S-Mg
    epsij[ "lj" "M" "H" ] = 0.1323 * FE_vdW_coeff  # Mg-H
    epsij[ "lj" "H" "M" ] = 0.1323 * FE_vdW_coeff  # H-Mg
    epsij[ "lj" "M" "f" ] = 0.0935 * FE_vdW_coeff  # Mg-Fe
    epsij[ "lj" "f" "M" ] = 0.0935 * FE_vdW_coeff  # Fe-Mg
    epsij[ "lj" "M" "F" ] = 0.2646 * FE_vdW_coeff  # Mg-F
    epsij[ "lj" "F" "M" ] = 0.2646 * FE_vdW_coeff  # F-Mg
    epsij[ "lj" "M" "c" ] = 0.4914 * FE_vdW_coeff  # Mg-Cl
    epsij[ "lj" "c" "M" ] = 0.4914 * FE_vdW_coeff  # Cl-Mg
    epsij[ "lj" "M" "b" ] = 0.5834 * FE_vdW_coeff  # Mg-Br
    epsij[ "lj" "b" "M" ] = 0.5834 * FE_vdW_coeff  # Br-Mg
    epsij[ "lj" "M" "I" ] = 0.6950 * FE_vdW_coeff  # Mg-I
    epsij[ "lj" "I" "M" ] = 0.6950 * FE_vdW_coeff  # I-Mg
    epsij[ "lj" "M" "M" ] = 0.8750 * FE_vdW_coeff  # Mg-Mg
    epsij[ "lj" "M" "Z" ] = 0.6937 * FE_vdW_coeff  # Mg-Zn
    epsij[ "lj" "Z" "M" ] = 0.6937 * FE_vdW_coeff  # Zn-Mg
    epsij[ "lj" "M" "L" ] = 0.6937 * FE_vdW_coeff  # Mg-Ca
    epsij[ "lj" "L" "M" ] = 0.6937 * FE_vdW_coeff  # Ca-Mg
    epsij[ "lj" "M" "X" ] = 0.1323 * FE_vdW_coeff  # Mg-Xx
    epsij[ "lj" "X" "M" ] = 0.1323 * FE_vdW_coeff  # Xx-Mg

    epsij[ "lj" "Z" "C" ] = 0.2872 * FE_vdW_coeff  # Zn-C
    epsij[ "lj" "C" "Z" ] = 0.2872 * FE_vdW_coeff  # C-Zn
    epsij[ "lj" "Z" "N" ] = 0.2966 * FE_vdW_coeff  # Zn-N
    epsij[ "lj" "N" "Z" ] = 0.2966 * FE_vdW_coeff  # N-Zn
    epsij[ "lj" "Z" "O" ] = 0.3317 * FE_vdW_coeff  # Zn-O
    epsij[ "lj" "O" "Z" ] = 0.3317 * FE_vdW_coeff  # O-Zn
    epsij[ "lj" "Z" "P" ] = 0.3317 * FE_vdW_coeff  # Zn-P
    epsij[ "lj" "P" "Z" ] = 0.3317 * FE_vdW_coeff  # P-Zn
    epsij[ "lj" "Z" "S" ] = 0.3317 * FE_vdW_coeff  # Zn-S
    epsij[ "lj" "S" "Z" ] = 0.3317 * FE_vdW_coeff  # S-Zn
    epsij[ "lj" "Z" "H" ] = 0.1049 * FE_vdW_coeff  # Zn-H
    epsij[ "lj" "H" "Z" ] = 0.1049 * FE_vdW_coeff  # H-Zn
    epsij[ "lj" "Z" "f" ] = 0.0742 * FE_vdW_coeff  # Zn-Fe
    epsij[ "lj" "f" "Z" ] = 0.0742 * FE_vdW_coeff  # Fe-Zn
    epsij[ "lj" "Z" "F" ] = 0.2098 * FE_vdW_coeff  # Zn-F
    epsij[ "lj" "F" "Z" ] = 0.2098 * FE_vdW_coeff  # F-Zn
    epsij[ "lj" "Z" "c" ] = 0.3896 * FE_vdW_coeff  # Zn-Cl
    epsij[ "lj" "c" "Z" ] = 0.3896 * FE_vdW_coeff  # Cl-Zn
    epsij[ "lj" "Z" "b" ] = 0.4625 * FE_vdW_coeff  # Zn-Br
    epsij[ "lj" "b" "Z" ] = 0.4625 * FE_vdW_coeff  # Br-Zn
    epsij[ "lj" "Z" "I" ] = 0.5510 * FE_vdW_coeff  # Zn-I
    epsij[ "lj" "I" "Z" ] = 0.5510 * FE_vdW_coeff  # I-Zn
    epsij[ "lj" "Z" "M" ] = 0.6937 * FE_vdW_coeff  # Zn-Mg
    epsij[ "lj" "M" "Z" ] = 0.6937 * FE_vdW_coeff  # Mg-Zn
    epsij[ "lj" "Z" "Z" ] = 0.5500 * FE_vdW_coeff  # Zn-Zn
    epsij[ "lj" "Z" "L" ] = 0.5500 * FE_vdW_coeff  # Zn-Ca
    epsij[ "lj" "L" "Z" ] = 0.5500 * FE_vdW_coeff  # Ca-Zn
    epsij[ "lj" "Z" "X" ] = 0.1049 * FE_vdW_coeff  # Zn-Xx
    epsij[ "lj" "X" "Z" ] = 0.1049 * FE_vdW_coeff  # Xx-Zn

    epsij[ "lj" "L" "C" ] = 0.2872 * FE_vdW_coeff  # Ca-C
    epsij[ "lj" "C" "L" ] = 0.2872 * FE_vdW_coeff  # C-Ca
    epsij[ "lj" "L" "N" ] = 0.2966 * FE_vdW_coeff  # Ca-N
    epsij[ "lj" "N" "L" ] = 0.2966 * FE_vdW_coeff  # N-Ca
    epsij[ "lj" "L" "O" ] = 0.3317 * FE_vdW_coeff  # Ca-O
    epsij[ "lj" "O" "L" ] = 0.3317 * FE_vdW_coeff  # O-Ca
    epsij[ "lj" "L" "P" ] = 0.3317 * FE_vdW_coeff  # Ca-P
    epsij[ "lj" "P" "L" ] = 0.3317 * FE_vdW_coeff  # P-Ca
    epsij[ "lj" "L" "S" ] = 0.3317 * FE_vdW_coeff  # Ca-S
    epsij[ "lj" "S" "L" ] = 0.3317 * FE_vdW_coeff  # S-Ca
    epsij[ "lj" "L" "H" ] = 0.1049 * FE_vdW_coeff  # Ca-H
    epsij[ "lj" "H" "L" ] = 0.1049 * FE_vdW_coeff  # H-Ca
    epsij[ "lj" "L" "f" ] = 0.0742 * FE_vdW_coeff  # Ca-Fe
    epsij[ "lj" "f" "L" ] = 0.0742 * FE_vdW_coeff  # Fe-Ca
    epsij[ "lj" "L" "F" ] = 0.2098 * FE_vdW_coeff  # Ca-F
    epsij[ "lj" "F" "L" ] = 0.2098 * FE_vdW_coeff  # F-Ca
    epsij[ "lj" "L" "c" ] = 0.3896 * FE_vdW_coeff  # Ca-Cl
    epsij[ "lj" "c" "L" ] = 0.3896 * FE_vdW_coeff  # Cl-Ca
    epsij[ "lj" "L" "b" ] = 0.4625 * FE_vdW_coeff  # Ca-Br
    epsij[ "lj" "b" "L" ] = 0.4625 * FE_vdW_coeff  # Br-Ca
    epsij[ "lj" "L" "I" ] = 0.5510 * FE_vdW_coeff  # Ca-I
    epsij[ "lj" "I" "L" ] = 0.5510 * FE_vdW_coeff  # I-Ca
    epsij[ "lj" "L" "M" ] = 0.6937 * FE_vdW_coeff  # Ca-Mg
    epsij[ "lj" "M" "L" ] = 0.6937 * FE_vdW_coeff  # Mg-Ca
    epsij[ "lj" "L" "Z" ] = 0.5500 * FE_vdW_coeff  # Ca-Zn
    epsij[ "lj" "Z" "L" ] = 0.5500 * FE_vdW_coeff  # Zn-Ca
    epsij[ "lj" "L" "L" ] = 0.5500 * FE_vdW_coeff  # Ca-Ca
    epsij[ "lj" "L" "X" ] = 0.1049 * FE_vdW_coeff  # Ca-Xx
    epsij[ "lj" "X" "L" ] = 0.1049 * FE_vdW_coeff  # Xx-Ca

    epsij[ "lj" "X" "C" ] = 0.0548 * FE_vdW_coeff  # Xx-C
    epsij[ "lj" "C" "X" ] = 0.0548 * FE_vdW_coeff  # C-Xx
    epsij[ "lj" "X" "N" ] = 0.0566 * FE_vdW_coeff  # Xx-N
    epsij[ "lj" "N" "X" ] = 0.0566 * FE_vdW_coeff  # N-Xx
    epsij[ "lj" "X" "O" ] = 0.0632 * FE_vdW_coeff  # Xx-O
    epsij[ "lj" "O" "X" ] = 0.0632 * FE_vdW_coeff  # O-Xx
    epsij[ "lj" "X" "P" ] = 0.0632 * FE_vdW_coeff  # Xx-P
    epsij[ "lj" "P" "X" ] = 0.0632 * FE_vdW_coeff  # P-Xx
    epsij[ "lj" "X" "S" ] = 0.0632 * FE_vdW_coeff  # Xx-S
    epsij[ "lj" "S" "X" ] = 0.0632 * FE_vdW_coeff  # S-Xx
    epsij[ "lj" "X" "H" ] = 0.0200 * FE_vdW_coeff  # Xx-H
    epsij[ "lj" "H" "X" ] = 0.0200 * FE_vdW_coeff  # H-Xx
    epsij[ "lj" "X" "f" ] = 0.0141 * FE_vdW_coeff  # Xx-Fe
    epsij[ "lj" "f" "X" ] = 0.0141 * FE_vdW_coeff  # Fe-Xx
    epsij[ "lj" "X" "F" ] = 0.0400 * FE_vdW_coeff  # Xx-F
    epsij[ "lj" "F" "X" ] = 0.0400 * FE_vdW_coeff  # F-Xx
    epsij[ "lj" "X" "c" ] = 0.0743 * FE_vdW_coeff  # Xx-Cl
    epsij[ "lj" "c" "X" ] = 0.0743 * FE_vdW_coeff  # Cl-Xx
    epsij[ "lj" "X" "b" ] = 0.0882 * FE_vdW_coeff  # Xx-Br
    epsij[ "lj" "b" "X" ] = 0.0882 * FE_vdW_coeff  # Br-Xx
    epsij[ "lj" "X" "I" ] = 0.1051 * FE_vdW_coeff  # Xx-I
    epsij[ "lj" "I" "X" ] = 0.1051 * FE_vdW_coeff  # I-Xx
    epsij[ "lj" "X" "M" ] = 0.1323 * FE_vdW_coeff  # Xx-Mg
    epsij[ "lj" "M" "X" ] = 0.1323 * FE_vdW_coeff  # Mg-Xx
    epsij[ "lj" "X" "Z" ] = 0.1049 * FE_vdW_coeff  # Xx-Zn
    epsij[ "lj" "Z" "X" ] = 0.1049 * FE_vdW_coeff  # Zn-Xx
    epsij[ "lj" "X" "L" ] = 0.1049 * FE_vdW_coeff  # Xx-Ca
    epsij[ "lj" "L" "X" ] = 0.1049 * FE_vdW_coeff  # Ca-Xx
    epsij[ "lj" "X" "X" ] = 0.0200 * FE_vdW_coeff  # Xx-Xx

#     epsij[ "lj" "C" "A" ] = 0.1500 * FE_vdW_coeff
#     epsij[ "lj" "A" "C" ] = epsij[ "lj" "C" "A" ]
#     epsij[ "lj" "A" "A" ] = epsij[ "lj" "C" "C" ]
#     epsij[ "lj" "A" "N" ] = epsij[ "lj" "C" "N" ]
#     epsij[ "lj" "A" "O" ] = epsij[ "lj" "C" "O" ]
#     epsij[ "lj" "A" "S" ] = epsij[ "lj" "C" "S" ]
#     epsij[ "lj" "A" "H" ] = epsij[ "lj" "C" "H" ]
#     epsij[ "lj" "N" "A" ] = epsij[ "lj" "A" "N" ]
#     epsij[ "lj" "O" "A" ] = epsij[ "lj" "A" "O" ]
#     epsij[ "lj" "S" "A" ] = epsij[ "lj" "A" "S" ]
#     epsij[ "lj" "H" "A" ] = epsij[ "lj" "A" "H" ]
#     epsij[ "lj" "A" "X" ] = epsij[ "lj" "C" "X" ]
#     epsij[ "lj" "A" "X" ] = epsij[ "lj" "C" "X" ]
#     epsij[ "lj" "X" "A" ] = epsij[ "lj" "A" "X" ]

    # A is aromatic C...
    epsij[ "lj" "C" "A" ] = 0.1500 * FE_vdW_coeff  # C-C
    epsij[ "lj" "A" "C" ] = 0.1500 * FE_vdW_coeff  # C-C
    epsij[ "lj" "A" "N" ] = 0.1549 * FE_vdW_coeff  # C-N
    epsij[ "lj" "N" "A" ] = 0.1549 * FE_vdW_coeff  # N-C
    epsij[ "lj" "A" "O" ] = 0.1732 * FE_vdW_coeff  # C-O
    epsij[ "lj" "O" "A" ] = 0.1732 * FE_vdW_coeff  # O-C
    epsij[ "lj" "A" "P" ] = 0.1732 * FE_vdW_coeff  # C-P
    epsij[ "lj" "P" "A" ] = 0.1732 * FE_vdW_coeff  # P-C
    epsij[ "lj" "A" "S" ] = 0.1732 * FE_vdW_coeff  # C-S
    epsij[ "lj" "S" "A" ] = 0.1732 * FE_vdW_coeff  # S-C
    epsij[ "lj" "A" "H" ] = 0.0548 * FE_vdW_coeff  # C-H
    epsij[ "lj" "H" "A" ] = 0.0548 * FE_vdW_coeff  # H-C
    epsij[ "lj" "A" "f" ] = 0.0387 * FE_vdW_coeff  # C-Fe
    epsij[ "lj" "f" "A" ] = 0.0387 * FE_vdW_coeff  # Fe-C
    epsij[ "lj" "A" "F" ] = 0.1095 * FE_vdW_coeff  # C-F
    epsij[ "lj" "F" "A" ] = 0.1095 * FE_vdW_coeff  # F-C
    epsij[ "lj" "A" "c" ] = 0.2035 * FE_vdW_coeff  # C-Cl
    epsij[ "lj" "c" "A" ] = 0.2035 * FE_vdW_coeff  # Cl-C
    epsij[ "lj" "A" "b" ] = 0.2416 * FE_vdW_coeff  # C-Br
    epsij[ "lj" "b" "A" ] = 0.2416 * FE_vdW_coeff  # Br-C
    epsij[ "lj" "A" "I" ] = 0.2877 * FE_vdW_coeff  # C-I
    epsij[ "lj" "I" "A" ] = 0.2877 * FE_vdW_coeff  # I-C
    epsij[ "lj" "A" "M" ] = 0.3623 * FE_vdW_coeff  # C-Mg
    epsij[ "lj" "M" "A" ] = 0.3623 * FE_vdW_coeff  # Mg-C
    epsij[ "lj" "A" "Z" ] = 0.2872 * FE_vdW_coeff  # C-Zn
    epsij[ "lj" "Z" "A" ] = 0.2872 * FE_vdW_coeff  # Zn-C
    epsij[ "lj" "A" "L" ] = 0.2872 * FE_vdW_coeff  # C-Ca
    epsij[ "lj" "L" "A" ] = 0.2872 * FE_vdW_coeff  # Ca-C
    epsij[ "lj" "A" "X" ] = 0.0548 * FE_vdW_coeff  # C-Xx
    epsij[ "lj" "X" "A" ] = 0.0548 * FE_vdW_coeff  # Xx-C

    #
    # Hydrogen-bonding parameters
    #
    Rij[ "hb" "N" "H" ] = 1.90
    Rij[ "hb" "O" "H" ] = 1.90
    Rij[ "hb" "S" "H" ] = 2.50
    Rij[ "hb" "H" "N" ] = 1.90
    Rij[ "hb" "H" "O" ] = 1.90
    Rij[ "hb" "H" "S" ] = 2.50

    #
    # AutoDock Binding Free Energy Model 140n
    # New well-depths multiplied by the hbond.difference
    # coefficient, 0.0656
    #

    #
    # Original enthalpic well-depths for hydrogen-bonding...
    #
    epsij[ "hb" "N" "H" ] = 5.0 * FE_hbond_coeff
    epsij[ "hb" "O" "H" ] = 5.0 * FE_hbond_coeff
    epsij[ "hb" "S" "H" ] = 1.0 * FE_hbond_coeff
    epsij[ "hb" "H" "N" ] = 5.0 * FE_hbond_coeff
    epsij[ "hb" "H" "O" ] = 5.0 * FE_hbond_coeff
    epsij[ "hb" "H" "S" ] = 1.0 * FE_hbond_coeff

}
$1 ~ /ATOM|HETATM|atom|hetatm/ {
#
#   Recognizable atom types are C,A,N,O,S,P & H
#   and...                      f,F,c,b,I
#   and...                      X,M (Any, Mg)
#   and...                      Z,L (Zn, Ca)
#   (note: A is aromatic carbon)
#   (f = iron, F=Fluorine, c=Chlorine, b=Bromine, I=iodine)
#   It is assumed that the 12-6 parameters of C can be used for P...
#
    card = substr($0,1,6)
    anum = substr($0,7,5)
    aname = substr($0,13,4)
    altloc = substr($0,17,1)
    resname = substr($0,18,3)
    chainid = substr($0,22,1)
    resnum = substr($0,23,4)
    inscode = substr($0,27,1)
    x = substr($0,31,8)
    y = substr($0,39,8)
    z = substr($0,47,8)
    occ = substr($0,55,6)
    tempfac = substr($0,61,6)
    footnot = substr($0,67,4)
    charge = substr($0,71,6)
    volume = substr($0,77,8)
    solpar = substr($0,85,8)

    pdbaname = aname      # Keep original format for output...
    if (substr(aname,1,1) == " ") {    # Delete the first blank: -xxx -> xxx
        aname = substr(aname,2,3)
    }
    if (substr(aname,4,1) == " ") {    # Delete the last blank: xxx- -> xxx
        aname = substr(aname,1,3)
    }
    if (substr(aname,3,1) == " ") {    # Delete the last blank: xx- -> xx
        aname = substr(aname,1,2)
    }
    if (substr(aname,2,1) == " ") {    # Delete the last blank: x- -> x
        aname = substr(aname,1,1)
    }
    #
    # Extract the 1-letter atom type code from the atom name in the PDB* file
    #
    atype_lig = substr(aname, 1,1)
    n[atype_lig]++
}
END {
    print "receptor <macromol>.pdbqs                #macromolecule"
    print "gridfld  <macromol>.maps.fld                #grid_data_file"
    print "npts     90 90 90                #num.grid points in xyz"
    print "spacing  .375                        #spacing (Angstroms)"
    print "gridcenter <xc> <yc> <zc>                #center_of_grids or auto"
    printf("types ")
    for (i = 1; i <= NUM_TYPES; i++) {
        type = substr(ALL_TYPES,i,1)  ## Note: type is a character, not int!
        if (n[type] != 0) {
          printf("%1s",type)
        }
    }
    printf("                        #atom type names\n")
    printf("smooth 0.500\t\t\t#store minimum energy within radius (Angstroms)\n")

    for (a_lig = 1; a_lig <= NUM_TYPES; a_lig++) {
        atype_lig = substr(ALL_TYPES, a_lig,1)
        if (n[atype_lig] != 0) {

            printf ("map <macromol>.%s.map                        #filename of grid map\n",atype_lig)

            ## Rebecca Wade email: Thu, 20 Apr 2000
            ## RebeccaWade if (atype_lig == "A") { # some lines for "A" are not here yet.
            ## RebeccaWade                atype_lig = "C"
            ## RebeccaWade }
#            Note: types N,O,S can H-bond...
#            But: nitrogen in >N-H, as in amides, has no free lone pairs, 
#            so CANNOT accept H-bonds!

            if ((atype_lig == "O")||(atype_lig == "S")) {
                set_hb_acc_1 = ON
            } else {
                set_hb_acc_1 = OFF
            }
            if (atype_lig == "H") {
                set_hb_don_1 = ON
            } else {
                set_hb_don_1 = OFF
            }

            for (a_pro = 1; a_pro <= length(PROTEIN_ATOMTYPES); a_pro++) {
                atype_pro = substr(PROTEIN_ATOMTYPES, a_pro, 1)
                bond      = "lj"
                exponent1 =  12
                exponent2 =   6
                if ( ((set_hb_acc_1 == ON) && (atype_pro == "H")) ||
                ((set_hb_don_1 == ON) && ((atype_pro == "O")||(atype_pro == "S"))) ) {
                    bond      = "hb"
                    exponent1 =  12
                    exponent2 =  10
                }

                printf ("nbp_r_eps %5.2f %9.7f %2d %2d\t#%1s-%1s %s\n", \
                Rij[ bond atype_lig atype_pro ], epsij[ bond atype_lig atype_pro ], \
                exponent1, exponent2, atype_lig, atype_pro, bond )
            } #for a_pro

            printf("sol_par %5.2f %6.4f                #%1s atomic fragmental volume, solvation param.\n", SolVol[ atype_lig ], SolPar[ atype_lig ], atype_lig)
            printf("constant %5.3f                        #%1s grid map constant energy\n", SolCon[ atype_lig ], atype_lig)
        } #if natype_lig!=0
    } #for a_lig

    print "elecmap <macromol>.e.map                #electrostatic potential map"
    printf("dielectric %.4f                #<0,distance-dep.diel; >0,constant\n", -FE_estat_coeff) # minus is needed
    print "#fmap <macromol>.f.map                #floating grid"
    print "# gpf3gen.awk 3.0.5 #"
}
