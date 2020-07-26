CXX_FLAGS = -O3 -march=native -mtune=native -flto -fuse-linker-plugin --std=c++2a
LINKER_FLAGS = -lbenchmark -lpthread

benchmark : mergesort.o
	g++ mergesort.o benchmark.cpp ${CXX_FLAGS} ${LINKER_FLAGS} -o benchmark.out

mergesort.o : mergesort.cpp
	g++ -c mergesort.cpp ${CXX_FLAGS} -o mergesort.o

clean :
	rm -rf benchmark.out
	rm -rf *.o