#import "iLocatorApp.h"
#import <unistd.h>

void usage(void)
{
    NSLog(@"Usage: iLocator [-d][-h][-u <update time>]");
    exit(0);
}

int main(int argc, char **argv)
{
    int f_daemon = 0;
    int update_delay = 30;
    extern char *optarg;
    extern int optind, optopt, opterr;
    int c;

    while ((c = getopt(argc, argv, "hdu:")) != -1)
    {
        switch (c)
        {
	case 'h':
	    usage();
	    break;
        case 'd':
	    f_daemon = 1;
            break;
	case 'u':
	    update_delay = atoi(optarg);
	    break;
        default:
	    usage();
            break;
        }
    }

    for ( ; optind < argc; optind++)
	usage();

    if (update_delay == 0)
	update_delay = 30;

    NSLog(@"Update delay %d\n", update_delay);
	
    /* run as daemon */
    if (f_daemon) {
	int ret = daemon(0, 1);

	if (ret) {
	    perror("iLocator daemon failed");
	    exit(1);
	}
    }

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    iLocatorApp *il = [iLocatorApp alloc];
    [il setUpdateDelay: update_delay];
    [il main];

    [pool release];
    return 0;
}
