/******************************************************
*Project description：driver_template.c
*Time：2011-12-12
*Author: 
*******************************************************/

/*头文件*/
#include<linux/init.h>
#include<linux/module.h>
#include<linux/sched.h>
#include<linux/kernel.h>
#include <asm/uaccess.h>
#include<linux/device.h>
#include <linux/cdev.h>
#include <linux/fs.h>    

/*hello驱动的结构体*/
#define HELLO_DEVICE  "hello_test"
#define HELLO_NODE    "hello"

/*定义申请设备号(主设备号+次设备号)的变量*/
static dev_t num_dev;     

/*字符设备的变量定义*/
static struct cdev *cdev_p;

/*定义一个class类*/
static struct class *hello_class;

/*定义一个变量存储值*/
static unsigned char hello_value = 0;

static int hello_open(struct inode* inode,struct file* filp)
{
	/*增加管理此设备的 owner模块的使用计数*/
	printk(KERN_INFO"open the description successfully.\n");
	try_module_get(THIS_MODULE);
	return 0;
}

static int hello_release(struct inode* inode,struct file* filp)
{	
	/*减少管理此设备的 owner模块的使用计数*/
	printk(KERN_INFO"close the description successfully.\n");
	module_put(THIS_MODULE);
	return 0;
}

static ssize_t hello_read(struct file* filp,char __user *buf,size_t count,loff_t* f_pos)
{
	copy_to_user(buf, (char *)&hello_value, sizeof(unsigned char));
	return sizeof(unsigned char);

}

static ssize_t hello_write(struct file* filp,char __user *buf,size_t count,loff_t* f_pos)
{
	unsigned char value;
	if(count==1)
	{
		/*向用户空间写数据,如果写失败，则返回错误*/
		if(copy_from_user(&value, buf,sizeof(unsigned char)))
				return -EFAULT;
		hello_value=(value&0x0F);
		return sizeof(unsigned char);
	}else
	   return -EFAULT;
}

/*定义具体的文件操作*/
static struct file_operations hello_fops={
	.owner    = THIS_MODULE,
	.open     = hello_open,
	.release  = hello_release,
	.read     = hello_read,
	.write    = hello_write,
};

/*hello的初始化和hello设备驱动的加载*/
static int hello_ctrl_init(void)
{
	int err;
	struct device* temp=NULL;

	/*动态注册hello_test设备,num_dev为动态分配出来的设备号(主设备号+次设备号)*/
	err=alloc_chrdev_region(&num_dev,0,1,HELLO_DEVICE);
	if (err < 0) {
		printk(KERN_ERR "HELLO: unable to get device name %d/n", err);
		return err;
	}

	/*动态分配cdev内存空间*/
	cdev_p = cdev_alloc();
	cdev_p->ops = &hello_fops;

	/*加载设备驱动*/
	err=cdev_add(cdev_p,num_dev,1);
	if(err){
		printk(KERN_ERR "HELLO: unable to add the device %d/n", err);
		return err;
	}

	/*在/sys/class下创建hello_test目录*/
	hello_class=class_create(THIS_MODULE,HELLO_DEVICE);
	if(IS_ERR(hello_class))
	{
		err=PTR_ERR(hello_class);
		goto unregister_cdev;
	}

	/*基于/sys/class/hello_test和/dev下面创建hello设备文件*/
	temp=device_create(hello_class, NULL,num_dev, NULL, HELLO_NODE);
	if(IS_ERR(temp))
	{
		err=PTR_ERR(temp);
		goto unregister_class;
	}

	return 0;

unregister_class:
	class_destroy(hello_class);
unregister_cdev:
	cdev_del(cdev_p);
return err;
}

/*模块的初始化*/
static int __init hello_init(void)
{
	int ret;
	printk("The driver is insmoded successfully.\n");
	ret = hello_ctrl_init();
	if(ret)
	{
		printk(KERN_ERR "Apply: Hello_driver_init--Fail !!!/n");
		return ret;
	}
	return 0;
}

/*模块的退出*/
static void __exit hello_exit(void)
{
	printk("The driver is rmmoded successfully.\n");
	device_destroy(hello_class,num_dev);
	class_destroy(hello_class);
	cdev_del(cdev_p);
	unregister_chrdev_region(num_dev,1);
}

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("First Linux Driver");

module_init(hello_init);
module_exit(hello_exit);

