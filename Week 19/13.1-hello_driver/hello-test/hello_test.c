/*********************************************************************
* File£º	hello_test.c
* Author£º	
* Desc£º		
* History£º	
* Original version, 2012.02
* Program modify, 2012.02
*********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#define DEVICE_NAME "/dev/hello"

int main(int argc,char **argv)
{
	int fd,i;
	unsigned char val=0,value;
	fd=open("/dev/hello",O_RDWR);
	if(fd==-1){
		printf("Failed to open device %s.\n",DEVICE_NAME);
		return -1;
	}
	
	for(i=0;i<9;i++)
	{
		val=val+1;
		write(fd,&val,sizeof(val));
		if(read(fd,&value,sizeof(value))!=0)
		{
			printf("value=%0x:\n",value);
		}
		sleep(1);
	}
	close(fd);
	return 0;
}
