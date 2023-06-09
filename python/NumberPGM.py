def writeNumbers(F):
    temp=""
    for i in range(1,101):
        temp+=str(i)+"\n"
    F.write(temp)
f=open('number_file.txt','w')

writeNumbers(f)