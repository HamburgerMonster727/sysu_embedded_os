/******************************************************
*Project description�����Կ������ϵ�LED��
*Time��2011-12-12
*Author:
*******************************************************/

/*ͷ�ļ�*/
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
/*�����豸Ŀ¼*/
#define DEVICE_LIST  "led_test"

/*�����豸�ļ��ڵ�*/
#define DEVICE_NODE   "led_light"

#define LED1  0x01
#define LED2  0x02
#define LED3  0x04
#define LED4  0x08

/*���������豸��(���豸��+���豸��)�ı���*/
static dev_t num_dev;     

/*�ַ��豸�ı�������*/
static struct cdev *cdev_p;

/*����һ��class��*/
static struct class *led_dev_class;

/*����һ��ȫ�ֱ�������ʾLED�Ƶ�״̬*/
static unsigned char led_status = 0;

/*����LED�Ƶ�״̬*/
static void set_led_status(unsigned char status)
{
	/*��ʾLED�Ƶ�״̬�Ƿ����仯*/
	unsigned char led_status_changed;

	led_status_changed= led_status^(status & 0xF);
	
	/*���ݱ仯���*/
	led_status=(status & 0xF);
	
	/*���4��LED�Ƶ�״̬�����˱仯*/
	if(led_status_changed!=0x00)
	{
		/*�ж��Ƿ�ı�LED1�Ƶ�״̬*/
		if(led_status_changed&LED1)
		{
			if(led_status&LED1)
                                gpio_set_value(PAD_GPIO_A+30, 0);
			else
				gpio_set_value(PAD_GPIO_A+30, 1);
		}

		/*�ж��Ƿ�ı�LED2�Ƶ�״̬*/
		if(led_status_changed&LED2)
		{
			if(led_status&LED2)
                                gpio_set_value(PAD_GPIO_B+0, 0);
			else
				gpio_set_value(PAD_GPIO_B+0, 1);
		}

		/*�ж��Ƿ�ı�LED3�Ƶ�״̬*/
		if(led_status_changed&LED3)
		{
			if(led_status&LED3)
                                gpio_set_value(PAD_GPIO_B+10, 0);
			else
				gpio_set_value(PAD_GPIO_B+10, 1);
		}

		/*�ж��Ƿ�ı�LED4�Ƶ�״̬*/
		if(led_status_changed&LED4)
		{
			if(led_status&LED4)
                                gpio_set_value(PAD_GPIO_C+12, 0);
			else
				gpio_set_value(PAD_GPIO_C+12, 1);
		}

	}

}


/*��ȡLED�Ƶ�״̬*/
static ssize_t EXYNOS4412_led_read(struct file * file,char * buf,size_t count,loff_t * f_ops)
{
     /*���û��ռ��ȡ����,��ȡLED�Ƶ�״̬*/
    copy_to_user(buf, (char *)&led_status, sizeof(unsigned char));
    return sizeof(unsigned char); 
}

/*����ʵ��LED�Ƶ�д����*/
static ssize_t EXYNOS4412_led_write (struct file * file,const char * buf, size_t count,loff_t * f_ops)
{
	unsigned char status;
	if(count==1)
	{
		/*���û��ռ�д����,���дʧ�ܣ��򷵻ش���*/
		if(copy_from_user(&status, buf,sizeof(unsigned char)))
			return -EFAULT;
		set_led_status(status);
		return sizeof(unsigned char);
  }else
	   return -EFAULT;
}

/*��LED�豸*/
static ssize_t EXYNOS4412_led_open(struct inode * inode,struct file * file)
{	/*���ӹ�����豸�� ownerģ���ʹ�ü���*/
	try_module_get(THIS_MODULE);
	return 0;
}

/*�ͷ�LED�豸*/
static ssize_t EXYNOS4412_led_release(struct inode * inode, struct file * file)
{
	/*���ٹ�����豸�� ownerģ���ʹ�ü���*/
	module_put(THIS_MODULE);
	return 0;
}

/*���������ļ�����*/
static const struct file_operations EXYNOS4412_led_ctrl_ops={
    .owner        = THIS_MODULE,
    .open         = EXYNOS4412_led_open,
    .read         =	EXYNOS4412_led_read,
    .write        =	EXYNOS4412_led_write,
    .release      =	EXYNOS4412_led_release,
};

/*LED�Ƶĳ�ʼ����LED�豸�����ļ���*/
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


	/*��̬ע��led_test�豸,num_devΪ��̬����������豸��(���豸��+���豸��)*/
	err=alloc_chrdev_region(&num_dev,0,1,DEVICE_LIST);
	if (err < 0) {
		printk(KERN_ERR "LED: unable to get device name %d/n", err);
		return err;
	}
	
	/*��̬����cdev�ڴ�ռ�*/
	cdev_p = cdev_alloc();
	cdev_p->ops = &EXYNOS4412_led_ctrl_ops;

	/*�����豸����*/
	err=cdev_add(cdev_p,num_dev,1);
	if(err){
		printk(KERN_ERR "LED: unable to add the device %d/n", err);
		return err;
	}

	/*��/sys/class�´���led_testĿ¼*/
	led_dev_class=class_create(THIS_MODULE,DEVICE_LIST);
	if(IS_ERR(led_dev_class))
	{
        err=PTR_ERR(led_dev_class);
		goto unregister_cdev;
	}

	/*����/sys/class/led_test��/dev���洴��led_light�豸�ļ�*/
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

/*ģ��ĳ�ʼ��*/
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

/*ģ����˳�*/
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


