#!python3
import math

i_file = open("LPfilterprototype",'r')
text = i_file.readlines()
i_file.close()

for idx in range(len(text)):
    coef = float(text[idx])
    whole = 0
    if (coef >= 0):
        whole = int(math.floor(coef))
    else:
        whole = int(math.ceil(coef))
    fractional = coef - whole
    text[idx] = ((whole << 15) + int((fractional * (1 << 15))))

def tohex(val, nbits):
    return hex((val + (1 << nbits)) % (1 << nbits))[2:]

with open('filter_coef.mem', 'w') as w:
    for idx in range(len(text)):
        w.writelines(tohex(text[idx],16))
        w.writelines('\n')

