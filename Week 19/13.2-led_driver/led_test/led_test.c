/*********************************************************************
* File：	led_test.c
* Author：
* Desc：		
* History：	
* Original version, 2012.02 
* Program modify, 2012.02
*********************************************************************/

// LED test programme
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#define DEVICE_NODE "/dev/led_light"  //device point

int main(int argc,char **argv)
{
	int fd,i;
	unsigned char status;
	unsigned char t;

	/*打开设备节点*/
	fd = open(DEVICE_NODE,O_RDWR);
	if(fd == -1) 
	{
		printf("open device %s error \n",DEVICE_NODE);
		return -1;
	}

	while(1)
	{
		for(i=0;i<4;i++)
		{
			//依次点亮LED1..LED4
			t=(unsigned char)((1<<i)&0x0F);
			write(fd,&t,sizeof(t));
			if(read(fd,&status,1)!=0)
			{
				printf("led status:%0x\n",status);
			}
			sleep(1);
		}

	}
	close(fd);
	return 0;
}

