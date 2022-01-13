#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/vmalloc.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <asm/uaccess.h>
#include <linux/types.h>
#include <linux/moduleparam.h>
#include <linux/pci.h>
#include <asm/unistd.h>

MODULE_LICENSE("GPL");

#define MEM_MALLOC_SIZE 4096
#define MEM_MAJOR      246
#define MEM_MINOR    	0

char *mem_spvm;
struct cdev *mem_cdev;
struct class *mem_class;


static int __init driver_init_module(void);
static void __exit driver_exit_module(void);

static int mem_open(struct inode *ind, struct file *filp);
static int mem_release(struct inode *ind, struct file *filp);
static ssize_t mem_read(struct file *filp, char __user *buf, size_t size, loff_t *fpos);
static ssize_t mem_write(struct file *filp, const char __user *buf, size_t size, loff_t *fpos);

module_init(driver_init_module);
module_exit(driver_exit_module);

struct file_operations mem_fops = 
{
	.open = mem_open,
	.release = mem_release,
	.read = mem_read,
	.write = mem_write,
};

int __init driver_init_module(void)
{
	int res;

	int devno = MKDEV(MEM_MAJOR, 0);


	mem_spvm = (char *)vmalloc(MEM_MALLOC_SIZE);
	if (mem_spvm == NULL)
		printk(KERN_INFO"vmalloc failed!\n");
	else
		printk(KERN_INFO"vmalloc successfully! addr=0x%x\n", (unsigned int)mem_spvm);


	mem_cdev = cdev_alloc();
	if (mem_cdev == NULL)
	{
		printk(KERN_INFO"cdev_alloc failed!\n");
		return 0;
	}

	cdev_init(mem_cdev, &mem_fops);
	mem_cdev->owner = THIS_MODULE;
	mem_cdev->ops = &mem_fops;
	res = cdev_add(mem_cdev, devno, 1);

	if (res)
	{
		cdev_del(mem_cdev);
		mem_cdev = NULL;
		printk(KERN_INFO"cdev_add error\n");
	}
	else
	{
		printk(KERN_INFO"cdev_add ok\n");
	}

/* creating your own class */
    mem_class = class_create(THIS_MODULE, "myalloc");
    if(IS_ERR(mem_class)) {
        printk("Err: failed in creating class.\n");
       return -1;
    }
/* register your own device in sysfs, and this will cause udevd to create corresponding device node */
    device_create(mem_class, NULL, MKDEV(MEM_MAJOR,0), NULL, "myalloc");



	return 0;
}

void __exit driver_exit_module(void)
{

	
	if (mem_cdev != NULL)
		cdev_del(mem_cdev);
	printk(KERN_INFO"cdev_del ok\n");
    	device_destroy(mem_class, MKDEV(MEM_MAJOR, 0));
    	class_destroy(mem_class);

	if (mem_spvm != NULL)
		vfree(mem_spvm);
	printk(KERN_INFO"vfree ok!\n");
}

int mem_open(struct inode *ind, struct file *filp)
{
	printk(KERN_INFO"open vmalloc space\n");

	try_module_get(THIS_MODULE);//模块计数加1
	return 0;
}

int mem_release(struct inode *ind, struct file *filp)
{
	printk(KERN_INFO"close vmalloc space\n");

	module_put(THIS_MODULE);//模块计数减1
	return 0;
}

ssize_t mem_read(struct file *filp, char *buf, size_t size, loff_t *lofp)
{
	int res = -1;
	char *tmp;
	struct inode *inodep;

	inodep = filp->f_dentry->d_inode;

	tmp = mem_spvm;

	if (size > MEM_MALLOC_SIZE)
		size = MEM_MALLOC_SIZE;

	if (tmp != NULL)
		res = copy_to_user(buf, tmp, size);

	if (res == 0)
		return size;
	else
		return 0;
}

ssize_t mem_write(struct file *filp, const char *buf, size_t size, loff_t *lofp)
{
	int res = -1;
	char *tmp;
	struct inode *inodep;

	inodep = filp->f_dentry->d_inode;
		tmp = mem_spvm;

	if (size > MEM_MALLOC_SIZE)
		size = MEM_MALLOC_SIZE;

	if (tmp != NULL)
		res = copy_from_user(tmp, buf, size);

	if (res == 0)
		return size;
	else
		return 0;
}

