package com.espressif.ui.widgets;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Shader;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;


public class PaletteBar extends View {
    public static final String TAG = "PaletteBar";


    static final int RED = Color.rgb(255, 0, 0);
    static final int YELLOW = Color.rgb(255, 255, 0);
    static final int GREEN = Color.rgb(0, 255, 0);
    static final int TEAL = Color.rgb(128, 255, 255);
    static final int BLUE = Color.rgb(0, 0, 255);
    static final int VIOLET = Color.rgb(255, 0, 255);


    static int[] COLORS = {RED, YELLOW, GREEN, TEAL, BLUE, VIOLET, RED};
    private Paint rGBGradientPaint, backgroundPaint;
    static float x;

    private int mViewWidth = 0;
    private int mViewHeight = 0;

    private int mColorMargin;
    static private int mCurrentIntColor, mCurrentHueColor = 180; //default selected color i.e. teal

    float[] hsv = new float[3];
    private PaletteBarListener mListener;
    private boolean sizeChanged;
    private static float outerCircleRadius;
    private static float innerCircleRadius;
    private static int trackMarkHeight;
    private static int thumbCircleRadiusDP = 17;
    private static int trackMarkHeightDP = 10;


    public PaletteBar(Context context) {
        this(context, null);
    }

    public PaletteBar(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public PaletteBar(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);

        init(context);
    }


    public void init(Context context) {
        mColorMargin = dip2px(18);
        outerCircleRadius = dip2px(thumbCircleRadiusDP);

        innerCircleRadius = dip2px(thumbCircleRadiusDP - 2);
        trackMarkHeight = dip2px(trackMarkHeightDP);
        rGBGradientPaint = new Paint();
        rGBGradientPaint.setAntiAlias(true);

        backgroundPaint = new Paint();
        backgroundPaint.setAntiAlias(true);

        hsv[0] = mCurrentHueColor;
        hsv[1] = 10.0f;
        hsv[2] = 10.0f;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        drawColorPalette(canvas);
        drawSliderCircle(canvas);
    }

    private void drawSliderCircle(Canvas canvas) {
        hsv[0] = mCurrentHueColor;
        mCurrentIntColor = Color.HSVToColor(hsv);
        backgroundPaint.setColor(Color.WHITE);
        canvas.drawCircle(x, mViewHeight / 2f, outerCircleRadius, backgroundPaint);
        backgroundPaint.setColor(mCurrentIntColor);
        canvas.drawCircle(x, mViewHeight / 2f, innerCircleRadius, backgroundPaint);

    }


    private void drawColorPalette(Canvas canvas) {
        if (sizeChanged) {
            Shader gradient = new LinearGradient(mColorMargin, mColorMargin, mViewWidth - mColorMargin, mColorMargin, COLORS, null, Shader.TileMode.MIRROR);
            rGBGradientPaint.setShader(gradient);
            sizeChanged = false;
        }
        canvas.drawRoundRect(mColorMargin, (mViewHeight / 2f) - (trackMarkHeight / 2f), mViewWidth - mColorMargin, (mViewHeight / 2f) + (trackMarkHeight / 2f), 10, 10, rGBGradientPaint);
    }

    /**
     * for setting the color with "int hue (0-360)"
     */
    public void setColor(int hue) {
        mCurrentHueColor = hue;
        float percent = (mCurrentHueColor * 100) / 360f;
        x = (((mViewWidth - (mColorMargin * 2)) * percent) / 100) + mColorMargin;
        invalidate();
    }

    /**
     * for setting the ThumbCircleHeight"
     */
    public void setThumbCircleRadius(int dPRadius) {
        thumbCircleRadiusDP = dPRadius;
        invalidate();
    }

    /**
     * for setting the TrackMark height"
     */
    public void setTrackMarkHeight(int dPTrackMarkHeight) {
        trackMarkHeightDP = dPTrackMarkHeight;
        invalidate();
    }

    /**
     * Get the current colour
     */
    public int getCurrentColor() {
        return mCurrentHueColor;
    }

    @Override
    public void setEnabled(boolean enabled) {
        if (enabled == isEnabled()) {
            return;
        }
        super.setEnabled(enabled);
        if (isEnabled()) {
            setAlpha(1.0f);
        } else {
            setAlpha(0.3f);
        }
    }


    @Override
    protected void onSizeChanged(int w, int h, int oldW, int oldH) {
        super.onSizeChanged(w, h, oldW, oldH);
        sizeChanged = true;
        mViewWidth = w;
        mViewHeight = h;
        float percent = (mCurrentHueColor * 100) / 360f;
        x = (((mViewWidth - (mColorMargin * 2)) * percent) / 100) + mColorMargin;
    }

    private final OnTouchListener mTouchListener = new OnTouchListener() {

        @Override
        public boolean onTouch(View v, MotionEvent event) {
            x = event.getX();
            float y = event.getY();
            v.getParent().requestDisallowInterceptTouchEvent(true);

            if (x < mColorMargin)
                x = mColorMargin;
            if (x > mViewWidth - mColorMargin)
                x = mViewWidth - mColorMargin;

            mCurrentHueColor = getColorFromCoords(x, y);
            if (mListener != null && event.getAction() == MotionEvent.ACTION_UP) {
                mListener.onColorSelected(mCurrentHueColor);
                v.getParent().requestDisallowInterceptTouchEvent(false);
            }
            performClick();
            invalidate();
            return true;
        }
    };

    public int getColorFromCoords(float x, float y) {
        float percent = (x - mColorMargin) / (mViewWidth - (mColorMargin * 2)) * 100;
        float customHue = 360 * percent / 100;
        return Math.round(customHue);
    }

    public int dip2px(float dpValue) {
        final float scale = getResources().getDisplayMetrics().density;
        return (int) (dpValue * scale + 0.5f);
    }

    public void setListener(PaletteBarListener listener) {
        mListener = listener;

        // We'll start listening for touches now that the implementer cares about them
        if (listener == null) {
            setOnTouchListener(null);
        } else {
            setOnTouchListener(mTouchListener);
        }
    }

    /**
     * Interface for receiving color selection
     */
    public interface PaletteBarListener {
        void onColorSelected(int colorHue);
    }


}
