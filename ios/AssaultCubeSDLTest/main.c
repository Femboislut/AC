#include <SDL.h>
#define SDL_MAIN_NEEDED 1
#include <SDL_main.h>
#include <GL/gl.h>
#include <gl4esinit.h>

#include <stdio.h>

static SDL_Window *main_window = NULL;

static void get_main_framebuffer_size(int *width, int *height)
{
    if(main_window) SDL_GL_GetDrawableSize(main_window, width, height);
    else { *width = 0; *height = 0; }
}

int main(int argc, char **argv)
{
    (void)argc;
    (void)argv;

    if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0)
    {
        fprintf(stderr, "SDL_Init failed: %s\n", SDL_GetError());
        return 1;
    }

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 0);

    main_window = SDL_CreateWindow(
        "AssaultCube SDL / GL4ES Test",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        960,
        540,
        SDL_WINDOW_OPENGL | SDL_WINDOW_FULLSCREEN | SDL_WINDOW_ALLOW_HIGHDPI
    );
    if(!main_window)
    {
        fprintf(stderr, "SDL_CreateWindow failed: %s\n", SDL_GetError());
        SDL_Quit();
        return 2;
    }

    SDL_GLContext context = SDL_GL_CreateContext(main_window);
    if(!context)
    {
        fprintf(stderr, "SDL_GL_CreateContext failed: %s\n", SDL_GetError());
        SDL_DestroyWindow(main_window);
        SDL_Quit();
        return 3;
    }

    set_getprocaddress((void *(*)(const char *))SDL_GL_GetProcAddress);
    set_getmainfbsize(get_main_framebuffer_size);
    initialize_gl4es();

    SDL_GL_SetSwapInterval(1);
    int running = 1;
    int active = 1;
    unsigned int frame = 0;

    while(running)
    {
        SDL_Event event;
        while(SDL_PollEvent(&event))
        {
            switch(event.type)
            {
                case SDL_QUIT:
                    running = 0;
                    break;
                case SDL_APP_WILLENTERBACKGROUND:
                    active = 0;
                    break;
                case SDL_APP_DIDENTERFOREGROUND:
                    active = 1;
                    break;
                case SDL_WINDOWEVENT:
                    if(event.window.event == SDL_WINDOWEVENT_CLOSE) running = 0;
                    break;
            }
        }

        if(!active)
        {
            SDL_Delay(100);
            continue;
        }

        int width = 0, height = 0;
        SDL_GL_GetDrawableSize(main_window, &width, &height);
        glViewport(0, 0, width, height);

        // A changing clear colour makes a frozen frame or failed swap obvious.
        float phase = (float)(frame % 240) / 239.0f;
        glClearColor(0.08f + phase * 0.25f, 0.16f, 0.30f + (1.0f - phase) * 0.25f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        SDL_GL_SwapWindow(main_window);
        frame++;
        SDL_Delay(1);
    }

    close_gl4es();
    SDL_GL_DeleteContext(context);
    SDL_DestroyWindow(main_window);
    main_window = NULL;
    SDL_Quit();
    return 0;
}
