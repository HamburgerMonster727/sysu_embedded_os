/******************************************************
*Project description：测试开发板上的LED灯
*Time：2011-12-12
*Author:
*******************************************************/

/*头文件*/
#include<linux/init.h>
#include<linux/module.h>
#include<linux/sched.h>
#include<linux/kernel.h>
#include <asm/uaccess.h>
#include <linux/gpio.h>
#include <linux/cdev.h>
#include <linux/fs.h>    
#include <linux/device.h>
#include <cfg_type.h>
/*定义设备目录*/
#define DEVICE_LIST  "led_test"

/*定义设备文件节点*/
#define DEVICE_NODE   "led_light"

#define LED1  0x01
#define LED2  0x02
#define LED3  0x04
#define LED4  0x08

/*定义申请设备号(主设备号+次设备号)的变量*/
static dev_t num_dev;     

/*字符设备的变量定义*/
static struct cdev *cdev_p;

/*定义一个class类*/
static struct class *led_dev_class;

/*定义一个全局变量，表示LED灯的状态*/
static unsigned char led_status = 0;

/*设置LED灯的状态*/
static void set_led_status(unsigned char status)
{
	/*表示LED灯的状态是否发生变化*/
	unsigned char led_status_changed;

	led_status_changed= led_status^(status & 0xF);
	
	/*数据变化检测*/
	led_status=(status & 0xF);
	
	/*如果4个LED灯的状态发生了变化*/
	if(led_status_changed!=0x00)
	{
		/*判断是否改变LED1灯的状态*/
		if(led_status_changed&LED1)
		{
			if(led_status&LED1)
                                gpio_set_value(PAD_GPIO_A+30, 0);
			else
				gpio_set_value(PAD_GPIO_A+30, 1);
		}

		/*判断是否改变LED2灯的状态*/
		if(led_status_changed&LED2)
		{
			if(led_status&LED2)
                                gpio_set_value(PAD_GPIO_B+0, 0);
			else
				gpio_set_value(PAD_GPIO_B+0, 1);
		}

		/*判断是否改变LED3灯的状态*/
		if(led_status_changed&LED3)
		{
			if(led_status&LED3)
                                gpio_set_value(PAD_GPIO_B+10, 0);
			else
				gpio_set_value(PAD_GPIO_B+10, 1);
		}

		/*判断是否改变LED4灯的状态*/
		if(led_status_changed&LED4)
		{
			if(led_status&LED4)
                                gpio_set_value(PAD_GPIO_C+12, 0);
			else
				gpio_set_value(PAD_GPIO_C+12, 1);
		}

	}

}


/*读取LED灯的状态*/
static ssize_t EXYNOS4412_led_read(struct file * file,char * buf,size_t count,loff_t * f_ops)
{
     /*从用户空间读取数据,获取LED灯的状态*/
    copy_to_user(buf, (char *)&led_status, sizeof(unsigned char));
    return sizeof(unsigned char); 
}

/*定义实现LED灯的写操作*/
static ssize_t EXYNOS4412_led_write (struct file * file,const char * buf, size_t count,loff_t * f_ops)
{
	unsigned char status;
	if(count==1)
	{
		/*向用户空间写数据,如果写失败，则返回错误*/
		if(copy_from_user(&status, buf,sizeof(unsigned char)))
			return -EFAULT;
		set_led_status(status);
		return sizeof(unsigned char);
  }else
	   return -EFAULT;
}

/*打开LED设备*/
static ssize_t EXYNOS4412_led_open(struct inode * inode,struct file * file)
{	/*增加管理此设备的 owner模块的使用计数*/
	try_module_get(THIS_MODULE);
	return 0;
}

/*释放LED设备*/
static ssize_t EXYNOS4412_led_release(struct inode * inode, struct file * file)
{
	/*减少管理此设备的 owner模块的使用计数*/
	module_put(THIS_MODULE);
	return 0;
}

/*定义具体的文件操作*/
static const struct file_operations EXYNOS4412_led_ctrl_ops={
    .owner        = THIS_MODULE,
    .open         = EXYNOS4412_led_open,
    .read         =	EXYNOS4412_led_read,
    .write        =	EXYNOS4412_led_write,
    .release      =	EXYNOS4412_led_release,
};

/*LED灯的初始化和LED设备驱动的加载*/
static int EXYNOS4412_led_ctrl_init(void)
{
	int err, ret;
	struct device* temp=NULL;
	unsigned int gpio;
	
	gpio_free(PAD_GPIO_B+0);
	gpio_free(PAD_GPIO_A+30);
	gpio_free(PAD_GPIO_B+10);
	gpio_free(PAD_GPIO_C+12);
	ret = gpio_request(PAD_GPIO_B+0, "GPB0");
	if(ret)
		printk("mach-s4418: request gpio GPB0 fail");
	ret = gpio_request(PAD_GPIO_A+30, "GPB30");
	if(ret)
		printk("mach-s4418: request gpio GPB30 fail");
	ret = gpio_request(PAD_GPIO_B+10, "GPB10");
	if(ret)
		printk("mach-s4418: request gpio GPB10 fail");
	ret = gpio_request(PAD_GPIO_C+12, "GPC12");
	if(ret)
		printk("mach-s4418: request gpio GPC12 fail");

	gpio_direction_output(PAD_GPIO_A+30, 1);	
	gpio_direction_output(PAD_GPIO_B+0, 1);
	gpio_direction_output(PAD_GPIO_B+10, 1);
	gpio_direction_output(PAD_GPIO_C+12, 1);


	/*动态注册led_test设备,num_dev为动态分配出来的设备号(主设备号+次设备号)*/
	err=alloc_chrdev_region(&num_dev,0,1,DEVICE_LIST);
	if (err < 0) {
		printk(KERN_ERR "LED: unable to get device name %d/n", err);
		return err;
	}
	
	/*动态分配cdev内存空间*/
	cdev_p = cdev_alloc();
	cdev_p->ops = &EXYNOS4412_led_ctrl_ops;

	/*加载设备驱动*/
	err=cdev_add(cdev_p,num_dev,1);
	if(err){
		printk(KERN_ERR "LED: unable to add the device %d/n", err);
		return err;
	}

	/*在/sys/class下创建led_test目录*/
	led_dev_class=class_create(THIS_MODULE,DEVICE_LIST);
	if(IS_ERR(led_dev_class))
	{
        err=PTR_ERR(led_dev_class);
		goto unregister_cdev;
	}

	/*基于/sys/class/led_test和/dev下面创建led_light设备文件*/
	temp=device_create(led_dev_class, NULL,num_dev, NULL, DEVICE_NODE);
	if(IS_ERR(temp))
	{
		err=PTR_ERR(temp);
		goto unregister_class;
	}

	return 0;

unregister_class:
	class_destroy(led_dev_class);
unregister_cdev:
	cdev_del(cdev_p);
	return err;
}

/*模块的初始化*/
static int __init EXYNOS4412_led_init(void)
{
	int ret;

	ret = EXYNOS4412_led_ctrl_init();
	if(ret)
	{
		printk(KERN_ERR "Apply: s5p4418_LED_init--Fail !!!/n");
		return ret;
	}
	return 0;
}

/*模块的退出*/
static void __exit EXYNOS4412_led_exit(void)
{
	device_destroy(led_dev_class, num_dev);
	class_destroy(led_dev_class);
	cdev_del(cdev_p);
	unregister_chrdev_region(num_dev,1);
}

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("LED driver test");

module_init(EXYNOS4412_led_init);
module_exit(EXYNOS4412_led_exit);


