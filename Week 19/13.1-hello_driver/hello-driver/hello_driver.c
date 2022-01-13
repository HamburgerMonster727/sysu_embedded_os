/******************************************************
*Project description��driver_template.c
*Time��2011-12-12
*Author: 
*******************************************************/

/*ͷ�ļ�*/
#include<linux/init.h>
#include<linux/module.h>
#include<linux/sched.h>
#include<linux/kernel.h>
#include <asm/uaccess.h>
#include<linux/device.h>
#include <linux/cdev.h>
#include <linux/fs.h>    

/*hello�����Ľṹ��*/
#define HELLO_DEVICE  "hello_test"
#define HELLO_NODE    "hello"

/*���������豸��(���豸��+���豸��)�ı���*/
static dev_t num_dev;     

/*�ַ��豸�ı�������*/
static struct cdev *cdev_p;

/*����һ��class��*/
static struct class *hello_class;

/*����һ�������洢ֵ*/
static unsigned char hello_value = 0;

static int hello_open(struct inode* inode,struct file* filp)
{
	/*���ӹ�����豸�� ownerģ���ʹ�ü���*/
	printk(KERN_INFO"open the description successfully.\n");
	try_module_get(THIS_MODULE);
	return 0;
}

static int hello_release(struct inode* inode,struct file* filp)
{	
	/*���ٹ�����豸�� ownerģ���ʹ�ü���*/
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
		/*���û��ռ�д����,���дʧ�ܣ��򷵻ش���*/
		if(copy_from_user(&value, buf,sizeof(unsigned char)))
				return -EFAULT;
		hello_value=(value&0x0F);
		return sizeof(unsigned char);
	}else
	   return -EFAULT;
}

/*���������ļ�����*/
static struct file_operations hello_fops={
	.owner    = THIS_MODULE,
	.open     = hello_open,
	.release  = hello_release,
	.read     = hello_read,
	.write    = hello_write,
};

/*hello�ĳ�ʼ����hello�豸�����ļ���*/
static int hello_ctrl_init(void)
{
	int err;
	struct device* temp=NULL;

	/*��̬ע��hello_test�豸,num_devΪ��̬����������豸��(���豸��+���豸��)*/
	err=alloc_chrdev_region(&num_dev,0,1,HELLO_DEVICE);
	if (err < 0) {
		printk(KERN_ERR "HELLO: unable to get device name %d/n", err);
		return err;
	}

	/*��̬����cdev�ڴ�ռ�*/
	cdev_p = cdev_alloc();
	cdev_p->ops = &hello_fops;

	/*�����豸����*/
	err=cdev_add(cdev_p,num_dev,1);
	if(err){
		printk(KERN_ERR "HELLO: unable to add the device %d/n", err);
		return err;
	}

	/*��/sys/class�´���hello_testĿ¼*/
	hello_class=class_create(THIS_MODULE,HELLO_DEVICE);
	if(IS_ERR(hello_class))
	{
		err=PTR_ERR(hello_class);
		goto unregister_cdev;
	}

	/*����/sys/class/hello_test��/dev���洴��hello�豸�ļ�*/
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

/*ģ��ĳ�ʼ��*/
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

/*ģ����˳�*/
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

