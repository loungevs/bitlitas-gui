// Copyright (c) 2018, Bitlitas
// All rights reserved. Based on Monero.

#include "QrScanThread.h"
#include <QtGlobal>
#include <QDebug>

#if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
extern QImage qt_imageFromVideoFrame(const QVideoFrame &f);
#else
QImage qt_imageFromVideoFrame(const QVideoFrame &f){
    Q_ASSERT_X(0 != 0, "qt_imageFromVideoFrame", "Should have been managed in .pro");
    return QImage();
}
#endif

QrScanThread::QrScanThread(QObject *parent)
      : QThread(parent)
       ,m_running(true)
{
    m_scanner.set_handler(*this);
}

void QrScanThread::image_callback(zbar::Image &image)
{
    qDebug() << "image_callback :  Found Code ! " ;
    for(zbar::Image::SymbolIterator sym = image.symbol_begin();
        sym != image.symbol_end();
        ++sym)
        if(!sym->get_count()) {
            QString data = QString::fromStdString(sym->get_data());
            emit decoded(sym->get_type(), data);
        }
}

void QrScanThread::processZImage(zbar::Image &image)
{
    m_scanner.recycle_image(image);
    zbar::Image tmp = image.convert(*(long*)"Y800");
    m_scanner.scan(tmp);
    image.set_symbols(tmp.get_symbols());
}

bool QrScanThread::zimageFromQImage(const QImage &qimg, zbar::Image &dst)
{
    switch( qimg.format() ){
        case QImage::Format_RGB32 :
        case QImage::Format_ARGB32 :
        case QImage::Format_ARGB32_Premultiplied : 
            break;
        default :
            emit notifyError(QString("Invalid QImage Format !"));
            return false;
    }
    unsigned int bpl( qimg.bytesPerLine() ), width( bpl / 4), height( qimg.height());
    dst.set_size(width, height);
    dst.set_format("BGR4");
    unsigned long datalen = qimg.byteCount();
    dst.set_data(qimg.bits(), datalen);
    if((width * 4 != bpl) || (width * height * 4 > datalen)){
        emit notifyError(QString("QImage to Zbar::Image failed !"));
        return false;
    }
    return true;
}
void QrScanThread::processQImage(const QImage &qimg)
{
    try {
        m_image = QSharedPointer<zbar::Image>(new zbar::Image());
        if( ! zimageFromQImage(qimg, *m_image) )
            return;
        processZImage(*m_image);
    }
    catch(std::exception &e) {
        qDebug() << "ERROR: " << e.what();
        emit notifyError(e.what());
    }
}

void QrScanThread::processVideoFrame(const QVideoFrame &frame)
{
    processQImage( qt_imageFromVideoFrame(frame) );
}

void QrScanThread::stop()
{
    m_running = false;
    m_waitCondition.wakeOne();
}

void QrScanThread::addFrame(const QVideoFrame &frame)
{
    QMutexLocker locker(&m_mutex);
    m_queue.append(frame);
    m_waitCondition.wakeOne();
}

void QrScanThread::run()
{
    QVideoFrame frame;
    while(m_running) {
        QMutexLocker locker(&m_mutex);
        while(m_queue.isEmpty() && m_running)
            m_waitCondition.wait(&m_mutex);
        if(!m_queue.isEmpty())
            processVideoFrame(m_queue.takeFirst());
    }
}

