   /*�����嵥2.41led_drv.c�ο�����*/
#include <linux/init.h>
#include <linux/module.h>
#include <linux/version.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/platform_device.h>
#include <asm/gpio.h>

 #include "led_drv.h"
 
 static int major;
 static int minor;
 struct cdev *led;    /* cdev���ݽṹ*/
 static dev_t devno;           /* �豸���*/
 static struct class *led_class;
 static int led_io;/* ���ڱ���GPIO���*/
 
 #define DEVICE_NAME     "led"
 
 static int led_open(struct inode *inode, struct file *file )
 {
     try_module_get(THIS_MODULE);
     gpio_direction_output(led_io, 1);
     return 0;
 }
 
static int led_release(struct inode *inode, struct file *file )
 {
     module_put(THIS_MODULE);
     gpio_direction_output(led_io, 1);
     return 0;
 }
 
 #if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,36)
 int led_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
 #else 
 static int led_ioctl(struct inode *inode, struct file *file, unsigned int cmd, unsigned long arg)
 #endif
 {
     if (_IOC_TYPE(cmd) != LED_IOC_MAGIC) {
         return -ENOTTY;
     }
 
     if (_IOC_NR(cmd) > LED_IOCTL_MAXNR) {
         return -ENOTTY;
     }
 
     switch(cmd) {
     case LED_ON:
         gpio_set_value(led_io, 0);
         break;
 
     case LED_OFF:
         gpio_set_value(led_io, 1);
         break;
 
     default:
         gpio_set_value(led_io, 0);
         break;
     }
 
     return 0;
 }
 
 struct file_operations led_fops = {
     .owner   = THIS_MODULE,
     .open    = led_open,
     .release = led_release,
 #if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,36)
     .unlocked_ioctl = led_ioctl
 #else
     .ioctl   = led_ioctl
 #endif
 };
 
 static int  __devinitled_probe(struct platform_device *pdev)
 {
     int ret;
     struct resource *res_io;

     res_io = platform_get_resource(pdev, IORESOURCE_IO, 0);/*���豸��Դ��ȡIO����*/
     led_io = res_io->start;
 
     ret = alloc_chrdev_region(&devno, minor, 1, DEVICE_NAME); /* ��ϵͳ��ȡ���豸��*/
     major = MAJOR(devno);
     if (ret < 0) {
         printk(KERN_ERR "cannot get major %d \n", major);
         return -1;
     }
 
     led = cdev_alloc();                                        /* ����led�ṹ*/
if (led != NULL) {
         cdev_init(led, &led_fops);            /* ��ʼ��led�ṹ*/
         led->owner = THIS_MODULE;
         if (cdev_add(led, devno, 1) != 0) {                /* ����led��ϵͳ��*/
             printk(KERN_ERR "add cdev error!\n");
             goto error;
         }
     } else {
         printk(KERN_ERR "cdev_alloc error!\n");
         return -1;
     }
 
     led_class = class_create(THIS_MODULE, DEVICE_NAME"_class");
     if (IS_ERR(led_class)) {
         printk(KERN_INFO "create class error\n");
         return -1;
     }
 
     device_create(led_class, NULL, devno, NULL, DEVICE_NAME);
     return 0;
 
 error:
     unregister_chrdev_region(devno, 1);         /* �ͷ��Ѿ���õ��豸��*/
     return ret;
 }
 
 static int __devexit led_remove(struct platform_device *dev)
 {
     cdev_del(led);                                             /* �Ƴ��ַ��豸*/
     unregister_chrdev_region(devno, 1);                       /* �ͷ��豸��*/
     device_destroy(led_class, devno);
     class_destroy(led_class);
     return 0;
 }
 
 /* ����ͳ�ʼ��ƽ̨����*/
 static struct platform_driver led_platform_driver = {
     .probe  = led_probe,
     .remove = __devexit_p(led_remove),
     .driver = {
         .name = "led",/* �����Ʊ�����platform_device��.name��ͬ*/
         .owner = THIS_MODULE,
     },
 };
 
static int __init led_init(void)
{
return(platform_driver_register(&led_platform_driver));
}

static void __exit led_exit(void)
{
     platform_driver_unregister(&led_platform_driver);
}

module_init(led_init);
module_exit(led_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Chenxibing, linux@zlgmcu.com");